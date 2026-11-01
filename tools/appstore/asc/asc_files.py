"""Local files for the App Store Connect uploader: the metadata block format, text limits, PNG headers, MD5,
upload chunks, App Preview checks (ffprobe) and the IAP data file. No network here."""
from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
from dataclasses import dataclass, field
from decimal import Decimal

# App Store Connect text limits (characters).
LIMITS = {
    "name": 30,
    "subtitle": 30,
    "keywords": 100,
    "promotionalText": 170,
    "description": 4000,
    "whatsNew": 4000,
}
IAP_NAME_MAX = 30
IAP_DESC_MAX = 45
IAP_REVIEW_NOTE_MAX = 4000

# Fields of the `asc:<field>` blocks in marketing/appstore/<lang>-v2/metadata-<lang>.md.
TEXT_FIELDS = ("name", "subtitle", "keywords", "promotionalText", "description", "whatsNew")
URL_FIELDS = ("marketingUrl", "supportUrl", "privacyPolicyUrl")
SINGLE_LINE = {"name", "subtitle", "keywords", "promotionalText"} | set(URL_FIELDS)
ALL_FIELDS = TEXT_FIELDS + URL_FIELDS


class FileError(Exception):
    """A local file is missing, malformed or over a limit."""


# --------------------------------------------------------------------------------------------------------------------
# metadata-<lang>.md

FENCE_RE = re.compile(r"^(`{3,}|~{3,})\s*asc:([A-Za-z]+)\s*$")


@dataclass
class Metadata:
    fields: dict
    layout: str  # "blocks" (the strict asc: format) or "legacy-v2" (the tr-v2 draft's tables, read as a fallback)
    warnings: list = field(default_factory=list)


def parse_asc_blocks(text: str) -> dict:
    """The strict format: one fenced block per field, the info string is `asc:<field>`:

        ```asc:subtitle
        Sıcak Hava Balonu Tycoon Oyunu
        ```

    The block body is the value, byte for byte (only the final newline before the closing fence is dropped).
    Each field at most once; unknown fields and unclosed blocks are errors."""
    out: dict = {}
    lines = text.split("\n")
    i = 0
    while i < len(lines):
        m = FENCE_RE.match(lines[i].rstrip("\r"))
        if not m:
            i += 1
            continue
        fence, name = m.group(1), m.group(2)
        if name not in ALL_FIELDS:
            raise FileError(f"line {i + 1}: unknown field asc:{name} (known: {', '.join(ALL_FIELDS)})")
        if name in out:
            raise FileError(f"line {i + 1}: asc:{name} appears twice")
        body = []
        j = i + 1
        while j < len(lines) and lines[j].rstrip("\r").strip() != fence:
            body.append(lines[j].rstrip("\r"))
            j += 1
        if j >= len(lines):
            raise FileError(f"line {i + 1}: asc:{name} block is never closed with {fence}")
        value = "\n".join(body)
        if name in SINGLE_LINE:
            parts = [x for x in body if x.strip()]
            if len(parts) != 1:
                raise FileError(f"asc:{name} must be exactly one non-empty line (found {len(parts)})")
            value = parts[0].strip()
        out[name] = value
        i = j + 1
    return out


def _section(text: str, heading_prefix: str) -> str | None:
    """The body of the first `## <heading_prefix>…` section, up to the next `## ` heading."""
    m = re.search(r"^##\s+" + re.escape(heading_prefix) + r"[^\n]*\n(.*?)(?=^##\s|\Z)", text, re.M | re.S)
    return m.group(1) if m else None


def _table_cell(text: str, row_prefix: str) -> str | None:
    for line in text.split("\n"):
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) >= 2 and cells[0].startswith(row_prefix):
            return cells[1]
    return None


def parse_legacy_v2(text: str) -> dict:
    """Fallback for the tr-v2 draft written before the asc: blocks existed: the "Önerilen ad ve alt başlık" table
    (rows "Ad", "Alt başlık", "Anahtar kelimeler"), the first quote under "## Tanıtım metni" and the first code block
    under "## Açıklama"."""
    out = {}
    name = _table_cell(text, "Ad")
    sub = _table_cell(text, "Alt başlık")
    kw = _table_cell(text, "Anahtar kelimeler")
    if name:
        out["name"] = name.strip("`").strip()
    if sub:
        out["subtitle"] = sub.strip("`").strip()
    if kw:
        m = re.search(r"`([^`]+)`", kw)
        out["keywords"] = (m.group(1) if m else kw).strip()
    promo = _section(text, "Tanıtım metni")
    if promo:
        q = []
        for line in promo.split("\n"):
            if line.startswith(">"):
                q.append(line[1:].strip())
            elif q:
                break
        if q:
            out["promotionalText"] = " ".join(x for x in q if x)
    desc = _section(text, "Açıklama")
    if desc:
        m = re.search(r"^```[^\n]*\n(.*?)\n```", desc, re.M | re.S)
        if m:
            out["description"] = m.group(1)
    return out


def parse_metadata_md(text: str) -> Metadata:
    blocks = parse_asc_blocks(text)
    if blocks:
        return Metadata(blocks, "blocks")
    legacy = parse_legacy_v2(text)
    if not legacy:
        raise FileError("no ```asc:<field> blocks found (and the legacy v2 tables are not there either)")
    return Metadata(legacy, "legacy-v2", ["read with the legacy v2 layout; add ```asc:<field> blocks to make it strict"])


def check_text_fields(fields: dict, required=("name", "subtitle", "keywords", "promotionalText", "description")):
    """(errors, warnings) for one language's store texts."""
    errors, warnings = [], []
    for k in required:
        if not fields.get(k):
            errors.append(f"{k}: missing")
    for k, v in fields.items():
        if k in LIMITS and v is not None and len(v) > LIMITS[k]:
            errors.append(f"{k}: {len(v)} characters, limit {LIMITS[k]}")
        if k in URL_FIELDS and v and not re.match(r"^https?://\S+$", v):
            errors.append(f"{k}: not an http(s) URL: {v!r}")
        if isinstance(v, str) and re.search("[\U0001F300-\U0001FAFF\u2600-\u27BF]", v):
            warnings.append(f"{k}: contains an emoji or symbol Apple may reject")
    kw = fields.get("keywords")
    if kw:
        parts = kw.split(",")
        if any(p != p.strip() for p in parts):
            warnings.append("keywords: spaces around commas waste characters")
        if any(not p.strip() for p in parts):
            errors.append("keywords: empty keyword (double or trailing comma)")
        low = [p.strip().lower() for p in parts]
        dup = sorted({p for p in low if low.count(p) > 1})
        if dup:
            warnings.append(f"keywords: repeated: {', '.join(dup)}")
        for w in ("name", "subtitle"):
            words = set(re.findall(r"\w+", (fields.get(w) or "").lower()))
            rep = [p for p in low if p in words]
            if rep:
                warnings.append(f"keywords: already in the {w}: {', '.join(rep)}")
    return errors, warnings


# --------------------------------------------------------------------------------------------------------------------
# images, checksums, upload chunks

PNG_SIG = b"\x89PNG\r\n\x1a\n"


def png_info(path: str):
    """(width, height, has_alpha) from the PNG header; raises FileError for anything that isn't a PNG."""
    with open(path, "rb") as f:
        head = f.read(33)
    if len(head) < 33 or head[:8] != PNG_SIG or head[12:16] != b"IHDR":
        raise FileError(f"{path}: not a PNG file")
    w, h, _depth, ctype = struct.unpack(">IIBB", head[16:26])
    # colour types 4 (grey+alpha) and 6 (RGBA) carry alpha; a tRNS chunk would too (checked separately)
    alpha = ctype in (4, 6) or _png_has_trns(path)
    return w, h, alpha


def _png_has_trns(path: str) -> bool:
    with open(path, "rb") as f:
        f.read(8)
        while True:
            hdr = f.read(8)
            if len(hdr) < 8:
                return False
            n, kind = struct.unpack(">I4s", hdr)
            if kind == b"tRNS":
                return True
            if kind in (b"IDAT", b"IEND"):
                return False
            f.seek(n + 4, os.SEEK_CUR)


def md5_file(path: str, block: int = 1 << 20) -> str:
    h = hashlib.md5()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(block), b""):
            h.update(b)
    return h.hexdigest()


def plan_chunks(size: int, chunk: int):
    """[(offset, length)] covering [0, size) — the local preview of what Apple's uploadOperations will look like."""
    if size <= 0:
        return []
    return [(o, min(chunk, size - o)) for o in range(0, size, chunk)]


def check_upload_operations(ops: list, size: int):
    """Apple's uploadOperations must cover the file exactly once, in order; raises FileError otherwise."""
    if not ops:
        raise FileError("Apple returned no uploadOperations")
    pos = 0
    for op in sorted(ops, key=lambda o: o["offset"]):
        if op["offset"] != pos:
            raise FileError(f"uploadOperations leave a gap or overlap at byte {pos} (next offset {op['offset']})")
        if op["length"] <= 0:
            raise FileError("uploadOperation with zero length")
        pos += op["length"]
    if pos != size:
        raise FileError(f"uploadOperations cover {pos} bytes, file has {size}")


def read_chunk(path: str, offset: int, length: int) -> bytes:
    with open(path, "rb") as f:
        f.seek(offset)
        data = f.read(length)
    if len(data) != length:
        raise FileError(f"{path}: short read at {offset} ({len(data)} of {length} bytes)")
    return data


@dataclass
class Asset:
    path: str
    size: int
    md5: str
    width: int = 0
    height: int = 0
    info: dict = field(default_factory=dict)

    @property
    def name(self):
        return os.path.basename(self.path)


def check_screenshot(path: str, sizes) -> tuple[Asset, list]:
    """Asset plus a list of problems: dimensions must be one of `sizes` (portrait), PNG without alpha, < 10 MB…"""
    problems = []
    w, h, alpha = png_info(path)
    if [w, h] not in [list(s) for s in sizes]:
        problems.append(f"{os.path.basename(path)}: {w}x{h}, expected one of " + ", ".join(f"{a}x{b}" for a, b in sizes))
    if alpha:
        problems.append(f"{os.path.basename(path)}: has an alpha channel (App Store rejects transparency)")
    size = os.path.getsize(path)
    if size > 30 * 1024 * 1024:
        problems.append(f"{os.path.basename(path)}: {size} bytes is very large")
    return Asset(path, size, md5_file(path), w, h), problems


# --------------------------------------------------------------------------------------------------------------------
# App Previews

def ffprobe(path: str) -> dict:
    exe = shutil.which("ffprobe")
    if not exe:
        raise FileError("ffprobe not found (install ffmpeg: brew install ffmpeg / apt install ffmpeg)")
    r = subprocess.run([exe, "-v", "error", "-print_format", "json", "-show_streams", "-show_format", path],
                       capture_output=True, text=True)
    if r.returncode != 0:
        raise FileError(f"{path}: ffprobe failed: {r.stderr.strip()}")
    return json.loads(r.stdout)


def _fps(rate: str) -> float:
    if not rate or rate == "0/0":
        return 0.0
    a, _, b = rate.partition("/")
    return float(a) / float(b or 1)


def check_preview_probe(probe: dict, sizes) -> tuple[dict, list]:
    """Apple's App Preview rules: 15–30 s, ≤ 30 fps, H.264 or ProRes, portrait size from `sizes`, a stereo audio
    track (AAC or PCM), ≤ 500 MB."""
    problems = []
    v = next((s for s in probe.get("streams", []) if s.get("codec_type") == "video"), None)
    a = next((s for s in probe.get("streams", []) if s.get("codec_type") == "audio"), None)
    fmt = probe.get("format", {})
    info = {}
    if not v:
        return info, ["no video stream"]
    w, h = int(v.get("width", 0)), int(v.get("height", 0))
    dur = float(fmt.get("duration") or v.get("duration") or 0)
    fps = _fps(v.get("avg_frame_rate") or v.get("r_frame_rate"))
    info = {"width": w, "height": h, "duration": round(dur, 2), "fps": round(fps, 2), "codec": v.get("codec_name"),
            "profile": v.get("profile"), "audio": a and a.get("codec_name"), "channels": a and a.get("channels"),
            "sample_rate": a and a.get("sample_rate"), "bytes": int(fmt.get("size") or 0)}
    if [w, h] not in [list(s) for s in sizes]:
        problems.append(f"{w}x{h}, expected one of " + ", ".join(f"{x}x{y}" for x, y in sizes))
    if not 15 <= dur <= 30.5:
        problems.append(f"duration {dur:.2f} s (must be 15–30 s)")
    if fps > 30.01:
        problems.append(f"{fps:.2f} fps (at most 30)")
    if v.get("codec_name") not in ("h264", "prores"):
        problems.append(f"video codec {v.get('codec_name')} (H.264 or ProRes 422 HQ)")
    if not a:
        problems.append("no audio track (Apple wants one, silence is fine)")
    else:
        if a.get("codec_name") not in ("aac", "pcm_s16le", "pcm_s24le", "pcm_f32le"):
            problems.append(f"audio codec {a.get('codec_name')} (AAC or PCM)")
        if int(a.get("channels") or 0) != 2:
            problems.append(f"audio has {a.get('channels')} channels (stereo)")
    if info["bytes"] > 500 * 1024 * 1024:
        problems.append("larger than 500 MB")
    return info, problems


def check_preview(path: str, sizes) -> tuple[Asset, list]:
    probe = ffprobe(path)
    info, problems = check_preview_probe(probe, sizes)
    size = os.path.getsize(path)
    return Asset(path, size, md5_file(path), info.get("width", 0), info.get("height", 0), info), problems


TIMECODE_RE = re.compile(r"^\d\d:\d\d:\d\d:\d\d$")


# --------------------------------------------------------------------------------------------------------------------
# iap.json

def load_iap(path: str, langs) -> tuple[list, list]:
    """(products, errors). Every product needs productId, referenceName, price, reviewScreenshot, reviewNote and a
    name (≤30) + description (≤45) in every language of `langs`."""
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    errors = []
    seen = set()
    prods = data.get("products", [])
    for p in prods:
        pid = p.get("productId", "?")
        if pid in seen:
            errors.append(f"{pid}: listed twice")
        seen.add(pid)
        for k in ("productId", "referenceName", "price", "reviewScreenshot", "reviewNote"):
            if not p.get(k):
                errors.append(f"{pid}: {k} missing")
        if p.get("type", "NON_CONSUMABLE") != "NON_CONSUMABLE":
            errors.append(f"{pid}: type must be NON_CONSUMABLE")
        try:
            Decimal(str(p.get("price")))
        except Exception:
            errors.append(f"{pid}: price {p.get('price')!r} is not a number")
        if len(p.get("referenceName", "")) > 64:
            errors.append(f"{pid}: referenceName over 64 characters")
        if len(p.get("reviewNote", "")) > IAP_REVIEW_NOTE_MAX:
            errors.append(f"{pid}: reviewNote over {IAP_REVIEW_NOTE_MAX} characters")
        loc = p.get("localizations", {})
        for lang in langs:
            t = loc.get(lang)
            if not t:
                errors.append(f"{pid}: no {lang} localization")
                continue
            n, d = t.get("name", ""), t.get("description", "")
            if not 2 <= len(n) <= IAP_NAME_MAX:
                errors.append(f"{pid} [{lang}]: name {n!r} is {len(n)} characters (2–{IAP_NAME_MAX})")
            if not 1 <= len(d) <= IAP_DESC_MAX:
                errors.append(f"{pid} [{lang}]: description {d!r} is {len(d)} characters (1–{IAP_DESC_MAX})")
    return prods, errors


def storekit_products(path: str) -> dict:
    """productID → euro price from StoreKit/BalloonBaron.storekit."""
    with open(path, encoding="utf-8") as f:
        sk = json.load(f)
    return {p["productID"]: p["displayPrice"] for p in sk.get("products", [])}
