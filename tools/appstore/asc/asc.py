#!/usr/bin/env python3
"""Balloon Baron → App Store Connect: store texts, screenshots, App Previews and in-app purchases.

    python3 tools/appstore/asc/asc.py status
    python3 tools/appstore/asc/asc.py metadata    --langs tr,en [--dry-run | --yes]
    python3 tools/appstore/asc/asc.py screenshots --langs tr    [--dry-run | --yes] [--skip-previews]
    python3 tools/appstore/asc/asc.py previews    --langs tr    [--dry-run | --yes]
    python3 tools/appstore/asc/asc.py iap                       [--dry-run | --yes] [--overwrite]
    python3 tools/appstore/asc/asc.py all         --langs tr    [--dry-run | --yes]

Credentials: ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_P8 (PEM text) or ASC_KEY_P8_PATH. A dry run without them works
offline and shows the plan with placeholders. Never submits anything for review. See README.md (Turkish)."""
from __future__ import annotations

import argparse
import json
import logging
import os
import sys
import time
from decimal import Decimal

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from asc_client import Api, ApiError, Credentials, CredentialsError  # noqa: E402
from asc_files import (FileError, TIMECODE_RE, check_preview, check_screenshot, check_text_fields,  # noqa: E402
                       load_iap, md5_file, parse_metadata_md, plan_chunks, png_info, storekit_products)

log = logging.getLogger("asc")
DEFAULT_ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
ALL_LANGS = ["tr", "en", "de", "es", "ja", "ko"]
EDITABLE_VERSION = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED", "INVALID_BINARY"}
LIVE_INFO = {"READY_FOR_DISTRIBUTION", "READY_FOR_SALE", "REPLACED_WITH_NEW_INFO", "PROCESSING_FOR_DISTRIBUTION",
             "PROCESSING_FOR_APP_STORE"}
IAP_LOCKED = {"WAITING_FOR_REVIEW", "IN_REVIEW", "PENDING_BINARY_APPROVAL"}
VERSION_LOC_FIELDS = ("description", "keywords", "promotionalText", "marketingUrl", "supportUrl")
INFO_LOC_FIELDS = ("name", "subtitle", "privacyPolicyUrl")


class StepFailed(Exception):
    pass


class Report:
    def __init__(self, step):
        self.step, self.counts, self.warnings, self.missing = step, {}, [], []

    def count(self, what, n=1):
        self.counts[what] = self.counts.get(what, 0) + n

    def warn(self, msg):
        self.warnings.append(msg)
        log.warning(msg)

    def line(self):
        c = ", ".join(f"{k} {v}" for k, v in sorted(self.counts.items())) or "nothing to do"
        return f"{self.step}: {c}" + (f"; missing: {', '.join(self.missing)}" if self.missing else "") + (
            f"; {len(self.warnings)} warning(s)" if self.warnings else "")


class Ctx:
    def __init__(self, api: Api, cfg: dict, root: str, args):
        self.api, self.cfg, self.root, self.args = api, cfg, root, args
        self._app = None
        self._territories = None

    @property
    def dry(self):
        return self.api.dry_run

    def locales(self, lang):
        out = list(self.cfg["locales"][lang])
        if self.cfg.get("useExtraLocales") or getattr(self.args, "extra_locales", False):
            out += self.cfg.get("extraLocales", {}).get(lang, [])
        return out

    def lang_dir(self, lang):
        return os.path.join(self.root, "marketing", "appstore", f"{lang}-v2")


def attrs(obj):
    return (obj or {}).get("attributes") or {}


def rel(type_, id_):
    return {"data": {"type": type_, "id": id_}}


# ---------------------------------------------------------------------------------------------------- lookups

def find_app(ctx: Ctx):
    if ctx._app:
        return ctx._app
    bid = ctx.cfg["bundleId"]
    if ctx.api.offline:
        ctx._app = {"id": "<APP_ID>", "attributes": {"bundleId": bid, "name": "(offline: not looked up)"}}
        return ctx._app
    apps = ctx.api.get_all("/v1/apps", {"filter[bundleId]": bid, "fields[apps]": "name,bundleId,sku,primaryLocale"})
    apps = [a for a in apps if attrs(a).get("bundleId") == bid]
    if len(apps) != 1:
        raise StepFailed(f"expected one app with bundle id {bid}, found {len(apps)} (is the key's team the right one?)")
    ctx._app = apps[0]
    log.info("app %s (%s), id %s", attrs(apps[0]).get("name"), bid, apps[0]["id"])
    return ctx._app


def version_state(v):
    a = attrs(v)
    return a.get("appVersionState") or a.get("appStoreState") or "?"


def editable_version(ctx: Ctx):
    if ctx.api.offline:
        return {"id": "<VERSION_ID>", "attributes": {"versionString": "?", "appStoreState": "PREPARE_FOR_SUBMISSION"}}
    app = find_app(ctx)
    vs = ctx.api.get_all(f"/v1/apps/{app['id']}/appStoreVersions", {"filter[platform]": "IOS"})
    ed = [v for v in vs if (attrs(v).get("appVersionState") in EDITABLE_VERSION or
                            attrs(v).get("appStoreState") in EDITABLE_VERSION)]
    if not ed:
        raise StepFailed("no editable iOS App Store version (create version 1.0 in App Store Connect first); found: "
                         + ", ".join(f"{attrs(v).get('versionString')} {version_state(v)}" for v in vs))
    v = ed[0]
    log.info("editable version %s (%s), id %s", attrs(v).get("versionString"), version_state(v), v["id"])
    return v


def editable_app_info(ctx: Ctx):
    if ctx.api.offline:
        return {"id": "<APP_INFO_ID>"}
    app = find_app(ctx)
    infos = ctx.api.get_all(f"/v1/apps/{app['id']}/appInfos")
    ed = [i for i in infos if (attrs(i).get("state") or attrs(i).get("appStoreState")) not in LIVE_INFO]
    if not ed:
        raise StepFailed("no editable appInfo (the live one can't be changed; create a new version first)")
    return ed[0]


def territories(ctx: Ctx):
    if ctx._territories is None:
        if ctx.api.offline:
            ctx._territories = ["<EVERY_TERRITORY_FROM_/v1/territories>"]
        else:
            ctx._territories = [t["id"] for t in ctx.api.get_all("/v1/territories")]
            log.info("%d territories", len(ctx._territories))
    return ctx._territories


def version_localizations(ctx: Ctx, version):
    return {attrs(l)["locale"]: l for l in ctx.api.get_all(f"/v1/appStoreVersions/{version['id']}/appStoreVersionLocalizations")}


# ---------------------------------------------------------------------------------------------------- status

def cmd_status(ctx: Ctx):
    if ctx.api.offline:
        raise StepFailed("status needs credentials and network access to api.appstoreconnect.apple.com")
    api = ctx.api
    app = find_app(ctx)
    a = attrs(app)
    print(f"App: {a.get('name')}  bundle {a.get('bundleId')}  sku {a.get('sku')}  primary {a.get('primaryLocale')}  id {app['id']}")
    vs = api.get_all(f"/v1/apps/{app['id']}/appStoreVersions", {"filter[platform]": "IOS"})
    print("\nApp Store versions:")
    for v in vs:
        print(f"  {attrs(v).get('versionString'):8} {version_state(v):28} id {v['id']}  created {attrs(v).get('createdDate')}")
    ed = [v for v in vs if version_state(v) in EDITABLE_VERSION]
    if ed:
        v = ed[0]
        print(f"\nEditable version: {attrs(v).get('versionString')} ({version_state(v)})")
        for loc, l in sorted(version_localizations(ctx, v).items()):
            la = attrs(l)
            print(f"  {loc:6} description {len(la.get('description') or '')}  keywords {len(la.get('keywords') or '')}  "
                  f"promo {len(la.get('promotionalText') or '')}  support {la.get('supportUrl') or '-'}")
            for s in api.get_all(f"/v1/appStoreVersionLocalizations/{l['id']}/appScreenshotSets"):
                n = len(api.get_all(f"/v1/appScreenshotSets/{s['id']}/appScreenshots"))
                print(f"         screenshots {attrs(s).get('screenshotDisplayType')}: {n}")
            for s in api.get_all(f"/v1/appStoreVersionLocalizations/{l['id']}/appPreviewSets"):
                ps = api.get_all(f"/v1/appPreviewSets/{s['id']}/appPreviews")
                st = ", ".join(((attrs(p).get("assetDeliveryState") or {}).get("state") or "?") for p in ps)
                print(f"         previews {attrs(s).get('previewType')}: {len(ps)} {st}")
    else:
        print("\nNo editable version.")
    try:
        info = editable_app_info(ctx)
        print("\nApp info localizations:")
        for l in api.get_all(f"/v1/appInfos/{info['id']}/appInfoLocalizations"):
            la = attrs(l)
            print(f"  {la.get('locale'):6} name {la.get('name')!r}  subtitle {la.get('subtitle')!r}  privacy {la.get('privacyPolicyUrl') or '-'}")
    except StepFailed as e:
        print(f"\nApp info: {e}")
    iaps = api.get_all(f"/v1/apps/{app['id']}/inAppPurchasesV2")
    print(f"\nIn-app purchases ({len(iaps)}):")
    for i in sorted(iaps, key=lambda x: attrs(x).get("productId") or ""):
        ia = attrs(i)
        print(f"  {i['id']:12} {ia.get('productId'):26} {ia.get('inAppPurchaseType'):16} {ia.get('state'):22} {ia.get('name')}")
    try:
        prods, _ = load_iap(os.path.join(HERE, "iap.json"), ALL_LANGS)
        have = {attrs(i).get("productId") for i in iaps}
        miss = [p["productId"] for p in prods if p["productId"] not in have]
        print(f"  not in App Store Connect yet: {', '.join(miss) if miss else 'none'}")
    except Exception as e:  # status is read-only; a broken iap.json shouldn't hide the rest
        print(f"  (iap.json: {e})")


# ---------------------------------------------------------------------------------------------------- metadata

def load_texts(ctx: Ctx, langs, rep: Report):
    """{lang: fields} for every language whose md exists; validation errors raise before any request."""
    out, errors = {}, []
    urls = {k: v for k, v in (ctx.cfg.get("urls") or {}).items() if v}
    for lang in langs:
        path = os.path.join(ctx.lang_dir(lang), f"metadata-{lang}.md")
        if not os.path.isfile(path):
            rep.missing.append(f"{lang} (no {os.path.relpath(path, ctx.root)})")
            continue
        try:
            md = parse_metadata_md(open(path, encoding="utf-8").read())
        except FileError as e:
            errors.append(f"{lang}: {e}")
            continue
        fields = dict(md.fields)
        for k, v in urls.items():
            fields.setdefault(k, v)
        for w in md.warnings:
            rep.warn(f"{lang}: {w}")
        err, warn = check_text_fields(fields)
        errors += [f"{lang}: {e}" for e in err]
        for w in warn:
            rep.warn(f"{lang}: {w}")
        print(f"[{lang}] {os.path.relpath(path, ctx.root)} ({md.layout})")
        for k in ("name", "subtitle", "keywords", "promotionalText", "description", "supportUrl", "marketingUrl",
                  "privacyPolicyUrl"):
            v = fields.get(k)
            if v is None:
                continue
            show = v if len(v) <= 90 else v[:87].replace("\n", " ") + "…"
            lim = {"name": 30, "subtitle": 30, "keywords": 100, "promotionalText": 170, "description": 4000}.get(k)
            print(f"    {k:16} {len(v):5}{'/' + str(lim) if lim else '':6} {show}")
        out[lang] = fields
    for k in ("supportUrl", "privacyPolicyUrl"):
        if out and not any(f.get(k) for f in out.values()):
            rep.warn(f"{k} is not set (config.json urls.{k}); App Store Connect requires it before submission")
    if errors:
        raise StepFailed("metadata errors:\n  " + "\n  ".join(errors))
    return out


def upsert_localization(ctx: Ctx, rep: Report, existing: dict, locale: str, wanted: dict, kind: str, parent_rel: str,
                        parent_type: str, parent_id: str):
    wanted = {k: v for k, v in wanted.items() if v is not None}
    cur = existing.get(locale)
    if cur:
        diff = {k: v for k, v in wanted.items() if (attrs(cur).get(k) or "") != v}
        if not diff:
            rep.count(f"{kind} unchanged")
            return
        ctx.api.patch(f"/v1/{kind}/{cur['id']}", {"data": {"type": kind, "id": cur["id"], "attributes": diff}},
                      f"{locale}: {', '.join(diff)}")
        rep.count(f"{kind} updated")
    else:
        ctx.api.post(f"/v1/{kind}", {"data": {"type": kind, "attributes": {"locale": locale, **wanted},
                                              "relationships": {parent_rel: rel(parent_type, parent_id)}}}, f"new {locale}")
        rep.count(f"{kind} created")


def cmd_metadata(ctx: Ctx, langs):
    rep = Report("metadata")
    texts = load_texts(ctx, langs, rep)
    if not texts:
        rep.warn("no metadata files for the requested languages")
        return rep
    v = editable_version(ctx)
    info = editable_app_info(ctx)
    vlocs = version_localizations(ctx, v)
    ilocs = {attrs(l)["locale"]: l for l in ctx.api.get_all(f"/v1/appInfos/{info['id']}/appInfoLocalizations")}
    for lang, f in texts.items():
        for locale in ctx.locales(lang):
            print(f"\n[{lang} → {locale}] appStoreVersionLocalization + appInfoLocalization")
            upsert_localization(ctx, rep, vlocs, locale, {k: f.get(k) for k in VERSION_LOC_FIELDS},
                                "appStoreVersionLocalizations", "appStoreVersion", "appStoreVersions", v["id"])
            upsert_localization(ctx, rep, ilocs, locale, {k: f.get(k) for k in INFO_LOC_FIELDS},
                                "appInfoLocalizations", "appInfo", "appInfos", info["id"])
    return rep


# ---------------------------------------------------------------------------------------------------- uploads

def create_and_upload(ctx: Ctx, kind: str, parent_rel: str, parent_type: str, parent_id: str, asset, extra=None):
    """POST the reservation → send every uploadOperation chunk → PATCH uploaded=true with the MD5."""
    r = ctx.api.post(f"/v1/{kind}", {"data": {"type": kind, "attributes": {"fileName": asset.name, "fileSize": asset.size,
                                                                            **(extra or {})},
                                              "relationships": {parent_rel: rel(parent_type, parent_id)}}},
                     f"reserve {asset.name} ({asset.size} bytes)")
    obj = r.get("data") or {}
    ops = attrs(obj).get("uploadOperations") or []
    if ctx.dry:
        chunks = plan_chunks(asset.size, 5 * 1024 * 1024)
        print(f"  DRY-RUN upload {asset.name}: Apple's uploadOperations decide the chunks "
              f"(at ~5 MB that would be {len(chunks)}: " + ", ".join(f"{o}+{n}" for o, n in chunks[:4])
              + (" …" if len(chunks) > 4 else "") + ")")
    else:
        ctx.api.upload(asset.path, asset.size, ops)
    ctx.api.patch(f"/v1/{kind}/{obj.get('id')}", {"data": {"type": kind, "id": obj.get("id"),
                                                           "attributes": {"uploaded": True, "sourceFileChecksum": asset.md5}}},
                  f"commit {asset.name} md5 {asset.md5}")
    return obj.get("id")


def wait_delivered(ctx: Ctx, kind: str, ids, timeout: float, rep: Report, soft=False):
    """Polls assetDeliveryState until COMPLETE; FAILED raises (or warns when `soft`)."""
    if ctx.dry or not ids:
        return
    pending, start, delay = list(ids), time.time(), 2.0
    while pending:
        for i in list(pending):
            o = ctx.api.get_one(f"/v1/{kind}/{i}")
            st = (attrs(o).get("assetDeliveryState") or {})
            if st.get("state") == "COMPLETE":
                pending.remove(i)
            elif st.get("state") == "FAILED":
                msg = f"{kind} {i} ({attrs(o).get('fileName')}) failed: {st.get('errors')}"
                if soft:
                    rep.warn(msg)
                    pending.remove(i)
                else:
                    raise StepFailed(msg)
        if not pending:
            break
        if time.time() - start > timeout:
            msg = f"{len(pending)} {kind} still processing after {int(timeout)} s: {', '.join(pending)} (check with status)"
            if soft:
                rep.warn(msg)
                return
            raise StepFailed(msg)
        ctx.api.sleep(delay)
        delay = min(delay * 1.5, 15)
    log.info("%d %s delivered", len(ids), kind)


def local_screens(ctx: Ctx, lang, rep: Report):
    """{device: [Asset]} for marketing/appstore/<lang>-v2/{iphone,ipad}/*.png; problems raise."""
    out, problems = {}, []
    for dev, spec in ctx.cfg["screenshots"].items():
        d = os.path.join(ctx.lang_dir(lang), dev)
        files = sorted(f for f in os.listdir(d) if f.lower().endswith(".png")) if os.path.isdir(d) else []
        if not files:
            rep.missing.append(f"{lang}/{dev} screenshots")
            continue
        if len(files) > 10:
            problems.append(f"{lang}/{dev}: {len(files)} screenshots, at most 10")
        assets = []
        for f in files:
            if not (len(f) == 6 and f[:2].isdigit()):
                rep.warn(f"{lang}/{dev}/{f}: name is not NN.png; order follows the file name")
            a, p = check_screenshot(os.path.join(d, f), spec["sizes"])
            problems += [f"{lang}/{dev}/{x}" for x in p]
            assets.append(a)
        print(f"[{lang}] {dev}: {len(assets)} PNG → {spec['displayType']}")
        for a in assets:
            print(f"    {a.name}  {a.width}x{a.height}  {a.size:>9} B  md5 {a.md5}")
        out[dev] = assets
    if problems:
        raise StepFailed("screenshot problems:\n  " + "\n  ".join(problems))
    return out


def local_previews(ctx: Ctx, lang, rep: Report):
    out, problems = {}, []
    tc = ctx.cfg.get("previewFrameTimeCode", "00:00:05:00")
    if not TIMECODE_RE.match(tc):
        raise StepFailed(f"previewFrameTimeCode {tc!r} must be HH:MM:SS:FF")
    for dev, spec in ctx.cfg["previews"].items():
        p = os.path.join(ctx.lang_dir(lang), "preview", spec["file"])
        if not os.path.isfile(p):
            rep.missing.append(f"{lang}/preview/{spec['file']}")
            continue
        a, pr = check_preview(p, spec["sizes"])
        i = a.info
        print(f"[{lang}] preview/{spec['file']} → {spec['previewType']}: {i['width']}x{i['height']} {i['duration']} s "
              f"{i['fps']} fps {i['codec']} {i.get('profile') or ''}, audio {i['audio']} {i['channels']} ch "
              f"{i['sample_rate']} Hz, {a.size} B, md5 {a.md5}, poster frame {tc}")
        problems += [f"{lang}/preview/{spec['file']}: {x}" for x in pr]
        out[dev] = a
    if problems:
        raise StepFailed("App Preview problems:\n  " + "\n  ".join(problems))
    return out


def loc_id_for(ctx: Ctx, vlocs, locale, rep: Report):
    l = vlocs.get(locale)
    if l:
        return l["id"]
    if ctx.dry:
        rep.warn(f"{locale}: no appStoreVersionLocalization yet (metadata creates it); shown with a placeholder")
        return f"<LOC_ID {locale}>"
    raise StepFailed(f"{locale}: no appStoreVersionLocalization; run `metadata` first")


def sync_screenshot_set(ctx: Ctx, rep: Report, loc_id, display_type, assets):
    api = ctx.api
    sets = {attrs(s).get("screenshotDisplayType"): s for s in
            api.get_all(f"/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets")}
    s = sets.get(display_type)
    if s:
        sid = s["id"]
    else:
        r = api.post("/v1/appScreenshotSets", {"data": {"type": "appScreenshotSets",
                                                        "attributes": {"screenshotDisplayType": display_type},
                                                        "relationships": {"appStoreVersionLocalization": rel("appStoreVersionLocalizations", loc_id)}}},
                     f"new {display_type} set")
        sid = r["data"]["id"]
        rep.count("screenshot sets created")
    old = api.get_all(f"/v1/appScreenshotSets/{sid}/appScreenshots")
    old_sums = [attrs(o).get("sourceFileChecksum") for o in old]
    ok = all((attrs(o).get("assetDeliveryState") or {}).get("state") == "COMPLETE" for o in old)
    want = [a.md5 for a in assets]
    if ok and old_sums == want:
        print(f"  {display_type}: {len(old)} screenshots already up to date")
        rep.count("screenshot sets unchanged")
        return
    if ok and sorted(old_sums) == sorted(want) and len(set(want)) == len(want):
        by = {attrs(o).get("sourceFileChecksum"): o["id"] for o in old}
        api.patch(f"/v1/appScreenshotSets/{sid}/relationships/appScreenshots",
                  {"data": [{"type": "appScreenshots", "id": by[m]} for m in want]}, "reorder only")
        rep.count("screenshot sets reordered")
        return
    for o in old:
        api.delete(f"/v1/appScreenshots/{o['id']}", f"old {attrs(o).get('fileName')}")
        rep.count("screenshots deleted")
    ids = []
    for a in assets:
        ids.append(create_and_upload(ctx, "appScreenshots", "appScreenshotSet", "appScreenshotSets", sid, a))
        rep.count("screenshots uploaded")
    wait_delivered(ctx, "appScreenshots", ids, 600, rep)
    api.patch(f"/v1/appScreenshotSets/{sid}/relationships/appScreenshots",
              {"data": [{"type": "appScreenshots", "id": i} for i in ids]},
              "order " + ", ".join(a.name for a in assets))


def sync_preview_set(ctx: Ctx, rep: Report, loc_id, preview_type, asset, timecode):
    api = ctx.api
    sets = {attrs(s).get("previewType"): s for s in
            api.get_all(f"/v1/appStoreVersionLocalizations/{loc_id}/appPreviewSets")}
    s = sets.get(preview_type)
    if s:
        sid = s["id"]
    else:
        r = api.post("/v1/appPreviewSets", {"data": {"type": "appPreviewSets", "attributes": {"previewType": preview_type},
                                                     "relationships": {"appStoreVersionLocalization": rel("appStoreVersionLocalizations", loc_id)}}},
                     f"new {preview_type} preview set")
        sid = r["data"]["id"]
        rep.count("preview sets created")
    old = api.get_all(f"/v1/appPreviewSets/{sid}/appPreviews")
    same = [o for o in old if attrs(o).get("sourceFileChecksum") == asset.md5 and
            (attrs(o).get("assetDeliveryState") or {}).get("state") in ("COMPLETE", "UPLOAD_COMPLETE")]
    if len(old) == 1 and same:
        if attrs(same[0]).get("previewFrameTimeCode") != timecode:
            api.patch(f"/v1/appPreviews/{same[0]['id']}", {"data": {"type": "appPreviews", "id": same[0]["id"],
                                                                    "attributes": {"previewFrameTimeCode": timecode}}},
                      "poster frame")
            rep.count("previews updated")
        else:
            print(f"  {preview_type}: preview already up to date")
            rep.count("previews unchanged")
        return
    for o in old:
        api.delete(f"/v1/appPreviews/{o['id']}", f"old {attrs(o).get('fileName')}")
        rep.count("previews deleted")
    pid = create_and_upload(ctx, "appPreviews", "appPreviewSet", "appPreviewSets", sid, asset,
                            {"mimeType": "video/mp4", "previewFrameTimeCode": timecode})
    rep.count("previews uploaded")
    # Apple transcodes previews for a while; a slow one is a warning, not a failure
    wait_delivered(ctx, "appPreviews", [pid], 900, rep, soft=True)


def cmd_screenshots(ctx: Ctx, langs, screenshots=True, previews=True):
    rep = Report("screenshots" if screenshots and not previews else "previews" if previews and not screenshots
                 else "screenshots+previews")
    shots, vids = {}, {}
    for lang in langs:  # every local file is checked before the first request
        if screenshots:
            s = local_screens(ctx, lang, rep)
            if s:
                shots[lang] = s
        if previews:
            p = local_previews(ctx, lang, rep)
            if p:
                vids[lang] = p
    if not shots and not vids:
        rep.warn("no screenshot or preview files for the requested languages")
        return rep
    v = editable_version(ctx)
    vlocs = version_localizations(ctx, v)
    tc = ctx.cfg.get("previewFrameTimeCode", "00:00:05:00")
    for lang in langs:
        for locale in ctx.locales(lang):
            if lang not in shots and lang not in vids:
                continue
            print(f"\n[{lang} → {locale}]")
            lid = loc_id_for(ctx, vlocs, locale, rep)
            for dev, assets in shots.get(lang, {}).items():
                sync_screenshot_set(ctx, rep, lid, ctx.cfg["screenshots"][dev]["displayType"], assets)
            for dev, asset in vids.get(lang, {}).items():
                sync_preview_set(ctx, rep, lid, ctx.cfg["previews"][dev]["previewType"], asset, tc)
    return rep


# ---------------------------------------------------------------------------------------------------- IAP

def check_iap_files(ctx: Ctx, rep: Report):
    prods, errors = load_iap(os.path.join(HERE, "iap.json"), ALL_LANGS)
    sk_path = os.path.join(ctx.root, "StoreKit", "BalloonBaron.storekit")
    if os.path.isfile(sk_path):
        sk = storekit_products(sk_path)
        mine = {p["productId"]: p for p in prods}
        for pid, price in sk.items():
            if pid not in mine:
                errors.append(f"{pid}: in the .storekit file but not in iap.json")
            elif Decimal(str(mine[pid]["price"])) != Decimal(str(price)):
                errors.append(f"{pid}: iap.json price {mine[pid]['price']} ≠ .storekit {price}")
        for pid in mine:
            if pid not in sk:
                errors.append(f"{pid}: in iap.json but not in the .storekit file")
    else:
        rep.warn(f"{sk_path} not found; prices not cross-checked")
    for p in prods:
        f = os.path.join(HERE, p.get("reviewScreenshot", ""))
        if not os.path.isfile(f):
            errors.append(f"{p['productId']}: review screenshot {p.get('reviewScreenshot')} missing")
            continue
        try:
            w, h, alpha = png_info(f)
        except FileError as e:
            errors.append(str(e))
            continue
        if w < 640 or h < 920:
            errors.append(f"{p['productId']}: review screenshot {w}x{h} is smaller than 640x920")
        if alpha:
            errors.append(f"{p['productId']}: review screenshot has alpha")
        p["_shot"] = (f, os.path.getsize(f), md5_file(f), w, h)
    if errors:
        raise StepFailed("iap.json problems:\n  " + "\n  ".join(errors))
    base = ctx.args.base_territory or ctx.cfg["iap"]["baseTerritory"]
    print(f"{len(prods)} products, base territory {base}, locales " +
          ", ".join(l for lang in ALL_LANGS for l in ctx.locales(lang)))
    print(f"  {'productId':26} {'price':>5}  " + "  ".join(f"{l:18}" for l in ALL_LANGS))
    for p in prods:
        print(f"  {p['productId']:26} {p['price']:>5}  " + "  ".join(f"{p['localizations'][l]['name'][:18]:18}" for l in ALL_LANGS))
        print(f"  {'':26} {'':>5}  review/{os.path.basename(p['_shot'][0])} {p['_shot'][3]}x{p['_shot'][4]} {p['_shot'][1]} B md5 {p['_shot'][2]}")
    return prods, base


def iap_locale_texts(ctx: Ctx, p):
    out = {}
    for lang in ALL_LANGS:
        for locale in ctx.locales(lang):
            out[locale] = p["localizations"][lang]
    return out


def ensure_iap(ctx: Ctx, rep: Report, app_id, existing, p):
    pid = p["productId"]
    cur = existing.get(pid)
    want = {"name": p["referenceName"], "reviewNote": p["reviewNote"], "familySharable": bool(p.get("familySharable", False))}
    if not cur:
        r = ctx.api.post("/v2/inAppPurchases", {"data": {"type": "inAppPurchases", "attributes": {
            "productId": pid, "inAppPurchaseType": "NON_CONSUMABLE", **want},
            "relationships": {"app": rel("apps", app_id)}}}, f"new {pid}")
        rep.count("iap created")
        return r["data"]["id"], True
    a = attrs(cur)
    if a.get("inAppPurchaseType") != "NON_CONSUMABLE":
        raise StepFailed(f"{pid} exists as {a.get('inAppPurchaseType')}; the type can't be changed (delete it in App Store Connect, "
                         "but a product id can never be reused)")
    print(f"  exists: id {cur['id']}, state {a.get('state')}, reference {a.get('name')!r}")
    if a.get("state") in IAP_LOCKED:
        rep.warn(f"{pid}: {a.get('state')}; left as it is")
        return cur["id"], False
    diff = {}
    for k, v in want.items():
        have = a.get(k)
        if have in (None, "") or ctx.args.overwrite:
            if have != v:
                diff[k] = v
        elif have != v:
            if k == "familySharable" and have is True:
                rep.warn(f"{pid}: family sharing is on and can't be turned off")
            else:
                rep.warn(f"{pid}: {k} differs from iap.json ({have!r}); kept (use --overwrite to replace)")
    if diff.get("familySharable") is False and a.get("familySharable") is True:
        diff.pop("familySharable")
    if diff:
        ctx.api.patch(f"/v2/inAppPurchases/{cur['id']}", {"data": {"type": "inAppPurchases", "id": cur["id"], "attributes": diff}},
                      f"{pid}: {', '.join(diff)}")
        rep.count("iap updated")
    return cur["id"], True


def ensure_iap_localizations(ctx: Ctx, rep: Report, iap_id, p):
    have = {attrs(l)["locale"]: l for l in ctx.api.get_all(f"/v2/inAppPurchases/{iap_id}/inAppPurchaseLocalizations")}
    for locale, t in iap_locale_texts(ctx, p).items():
        want = {"name": t["name"], "description": t["description"]}
        cur = have.get(locale)
        if not cur:
            ctx.api.post("/v1/inAppPurchaseLocalizations", {"data": {"type": "inAppPurchaseLocalizations",
                                                                     "attributes": {"locale": locale, **want},
                                                                     "relationships": {"inAppPurchaseV2": rel("inAppPurchases", iap_id)}}},
                         f"{locale} {t['name']!r}")
            rep.count("iap localizations created")
            continue
        diff = {k: v for k, v in want.items() if (attrs(cur).get(k) or "") != v}
        if not diff:
            rep.count("iap localizations unchanged")
        elif ctx.args.overwrite:
            ctx.api.patch(f"/v1/inAppPurchaseLocalizations/{cur['id']}", {"data": {"type": "inAppPurchaseLocalizations",
                                                                                     "id": cur["id"], "attributes": diff}},
                          f"{locale}: {', '.join(diff)}")
            rep.count("iap localizations updated")
        else:
            rep.warn(f"{p['productId']} [{locale}]: " + ", ".join(f"{k} {attrs(cur).get(k)!r} ≠ {v!r}" for k, v in diff.items())
                     + "; kept (use --overwrite)")


def find_price_point(ctx: Ctx, iap_id, territory, price):
    if ctx.api.offline or iap_id.startswith("dry-"):
        return f"<PRICE_POINT {territory} {price}>"
    pts = ctx.api.get_all(f"/v2/inAppPurchases/{iap_id}/pricePoints",
                          {"filter[territory]": territory, "fields[inAppPurchasePricePoints]": "customerPrice,proceeds"})
    want = Decimal(str(price))
    for pt in pts:
        if Decimal(str(attrs(pt).get("customerPrice") or "-1")) == want:
            return pt["id"]
    near = sorted(pts, key=lambda x: abs(Decimal(str(attrs(x).get("customerPrice") or 0)) - want))[:3]
    raise StepFailed(f"no {territory} price point at {price}; nearest: " + ", ".join(attrs(x).get("customerPrice") for x in near))


def current_price(ctx: Ctx, iap_id):
    """(base territory, customer price in it) of the existing schedule, or None."""
    s = ctx.api.get_one(f"/v2/inAppPurchases/{iap_id}/iapPriceSchedule")
    if not s:
        return None
    bt = ctx.api.get_one(f"/v1/inAppPurchasePriceSchedules/{s['id']}/baseTerritory")
    base = bt["id"] if bt else None
    prices, inc = ctx.api.get_all(f"/v1/inAppPurchasePriceSchedules/{s['id']}/manualPrices",
                                  {"include": "inAppPurchasePricePoint,territory"}, with_included=True)
    pts = {(i["type"], i["id"]): i for i in inc}
    for pr in prices:
        r = pr.get("relationships") or {}
        terr = ((r.get("territory") or {}).get("data") or {}).get("id")
        pp = ((r.get("inAppPurchasePricePoint") or {}).get("data") or {}).get("id")
        if terr == base and not attrs(pr).get("endDate"):
            return base, attrs(pts.get(("inAppPurchasePricePoints", pp))).get("customerPrice")
    return base, None


def ensure_price(ctx: Ctx, rep: Report, iap_id, p, base):
    cur = None if iap_id.startswith("dry-") else current_price(ctx, iap_id)
    if cur:
        b, price = cur
        if b == base and price is not None and Decimal(str(price)) == Decimal(str(p["price"])):
            rep.count("prices unchanged")
            return
        if not ctx.args.overwrite:
            rep.warn(f"{p['productId']}: price schedule is {b} {price}, iap.json wants {base} {p['price']}; kept (use --overwrite)")
            return
    pp = find_price_point(ctx, iap_id, base, p["price"])
    ctx.api.post("/v1/inAppPurchasePriceSchedules", {
        "data": {"type": "inAppPurchasePriceSchedules", "relationships": {
            "inAppPurchase": rel("inAppPurchases", iap_id),
            "baseTerritory": rel("territories", base),
            "manualPrices": {"data": [{"type": "inAppPurchasePrices", "id": "${base-price}"}]}}},
        "included": [{"type": "inAppPurchasePrices", "id": "${base-price}", "attributes": {"startDate": None},
                      "relationships": {"inAppPurchaseV2": rel("inAppPurchases", iap_id),
                                        "inAppPurchasePricePoint": rel("inAppPurchasePricePoints", pp)}}]},
        f"{p['productId']}: {base} {p['price']} (Apple equalizes the other territories)")
    rep.count("prices set")


def ensure_availability(ctx: Ctx, rep: Report, iap_id, p):
    all_t = territories(ctx)
    new_terr = bool(ctx.cfg["iap"].get("availableInNewTerritories", True))
    av = None if iap_id.startswith("dry-") else ctx.api.get_one(f"/v2/inAppPurchases/{iap_id}/inAppPurchaseAvailability")
    if av:
        have = {t["id"] for t in ctx.api.get_all(f"/v1/inAppPurchaseAvailabilities/{av['id']}/availableTerritories")}
        if have >= set(all_t) and attrs(av).get("availableInNewTerritories") == new_terr:
            rep.count("availability unchanged")
            return
        if not ctx.args.overwrite and have:
            rep.warn(f"{p['productId']}: available in {len(have)} of {len(all_t)} territories; kept (use --overwrite)")
            return
    ctx.api.post("/v1/inAppPurchaseAvailabilities", {"data": {
        "type": "inAppPurchaseAvailabilities", "attributes": {"availableInNewTerritories": new_terr},
        "relationships": {"inAppPurchase": rel("inAppPurchases", iap_id),
                          "availableTerritories": {"data": [{"type": "territories", "id": t} for t in all_t]}}}},
        f"{p['productId']}: all {len(all_t) if not ctx.api.offline else ''} territories".replace("  ", " "))
    rep.count("availability set")


def ensure_review_shot(ctx: Ctx, rep: Report, iap_id, p):
    from asc_files import Asset
    f, size, md5, w, h = p["_shot"]
    asset = Asset(f, size, md5, w, h)
    cur = None if iap_id.startswith("dry-") else ctx.api.get_one(f"/v2/inAppPurchases/{iap_id}/appStoreReviewScreenshot")
    if cur:
        a = attrs(cur)
        st = (a.get("assetDeliveryState") or {}).get("state")
        if a.get("sourceFileChecksum") == md5 and st == "COMPLETE":
            rep.count("review screenshots unchanged")
            return
        if st == "COMPLETE" and not ctx.args.overwrite:
            rep.warn(f"{p['productId']}: has another review screenshot ({a.get('fileName')}); kept (use --overwrite)")
            return
        ctx.api.delete(f"/v1/inAppPurchaseAppStoreReviewScreenshots/{cur['id']}", f"old {a.get('fileName')} ({st})")
    sid = create_and_upload(ctx, "inAppPurchaseAppStoreReviewScreenshots", "inAppPurchaseV2", "inAppPurchases", iap_id, asset)
    rep.count("review screenshots uploaded")
    wait_delivered(ctx, "inAppPurchaseAppStoreReviewScreenshots", [sid], 300, rep)


def cmd_iap(ctx: Ctx):
    rep = Report("iap")
    prods, base = check_iap_files(ctx, rep)
    app = find_app(ctx)
    existing = {attrs(i).get("productId"): i for i in ctx.api.get_all(f"/v1/apps/{app['id']}/inAppPurchasesV2")}
    if not ctx.api.offline:
        found = [pid for pid in (p["productId"] for p in prods) if pid in existing]
        print(f"already in App Store Connect: {', '.join(found) or 'none'}")
        extra = sorted(set(existing) - {p["productId"] for p in prods})
        if extra:
            rep.warn("in App Store Connect but not in iap.json (left alone): " + ", ".join(extra))
    for p in prods:
        print(f"\n[{p['productId']}] {p['price']} €")
        iap_id, writable = ensure_iap(ctx, rep, app["id"], existing, p)
        if not writable:
            continue
        ensure_iap_localizations(ctx, rep, iap_id, p)
        ensure_price(ctx, rep, iap_id, p, base)
        ensure_availability(ctx, rep, iap_id, p)
        ensure_review_shot(ctx, rep, iap_id, p)
    return rep


# ---------------------------------------------------------------------------------------------------- main

def parse_langs(s):
    langs = [x.strip() for x in (s or ",".join(ALL_LANGS)).split(",") if x.strip()]
    bad = [x for x in langs if x not in ALL_LANGS]
    if bad:
        raise SystemExit(f"unknown language(s): {', '.join(bad)} (use {', '.join(ALL_LANGS)})")
    return langs


def confirm(args, what):
    if args.dry_run or args.yes:
        return
    if not sys.stdin.isatty():
        raise SystemExit("refusing to write without --yes (stdin is not a terminal); try --dry-run first")
    ans = input(f"\nThis writes {what} to App Store Connect. Continue? [y/N] ").strip().lower()
    if ans not in ("y", "yes", "e", "evet"):
        raise SystemExit("cancelled")


def build_parser():
    ap = argparse.ArgumentParser(prog="asc.py", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-v", "--verbose", action="store_true", help="debug logging (every request)")
    ap.add_argument("--root", default=DEFAULT_ROOT, help="repository root holding marketing/ and StoreKit/ (default: this repo)")
    ap.add_argument("--config", default=os.path.join(HERE, "config.json"))
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("status", help="read-only overview of the app in App Store Connect")

    def writer(name, help_, langs=True):
        p = sub.add_parser(name, help=help_)
        p.add_argument("--dry-run", action="store_true", help="validate files and print every request; write nothing")
        p.add_argument("--offline", action="store_true", help="with --dry-run: no requests at all, even with credentials")
        p.add_argument("--yes", action="store_true", help="write without asking")
        p.add_argument("--extra-locales", action="store_true", help="also en-GB and es-MX (config extraLocales)")
        if langs:
            p.add_argument("--langs", default=",".join(ALL_LANGS), help="tr,en,de,es,ja,ko (default: all)")
        return p

    writer("metadata", "store texts: appStoreVersionLocalizations + appInfoLocalizations")
    s = writer("screenshots", "screenshots and App Previews of the editable version")
    s.add_argument("--skip-previews", action="store_true")
    writer("previews", "App Previews only")
    i = writer("iap", "in-app purchases from iap.json", langs=False)
    i.add_argument("--overwrite", action="store_true", help="replace values that differ (default: only fill what's missing)")
    i.add_argument("--base-territory", help="override config iap.baseTerritory (e.g. DEU, TUR)")
    a = writer("all", "metadata, screenshots, previews, iap in order; stops at the first error")
    a.add_argument("--overwrite", action="store_true")
    a.add_argument("--base-territory")
    return ap


def main(argv=None):
    args = build_parser().parse_args(argv)
    logging.basicConfig(level=logging.DEBUG if args.verbose else logging.INFO,
                        format="%(asctime)s %(levelname)-7s %(message)s", datefmt="%H:%M:%S")
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    with open(args.config, encoding="utf-8") as f:
        cfg = json.load(f)
    for k in ("overwrite", "base_territory", "dry_run", "offline", "yes", "extra_locales"):
        if not hasattr(args, k):
            setattr(args, k, None)
    try:
        creds = Credentials.from_env()
    except CredentialsError as e:
        if args.cmd != "status" and args.dry_run:
            log.info("no credentials (%s): offline dry run, ids are placeholders", e)
            creds = None
        else:
            print(f"credentials: {e}\nSee tools/appstore/asc/README.md.", file=sys.stderr)
            return 2
    try:
        api = Api(None if args.offline else creds, dry_run=bool(args.dry_run))
    except CredentialsError as e:
        print(str(e), file=sys.stderr)
        return 2
    ctx = Ctx(api, cfg, os.path.abspath(args.root), args)
    if args.dry_run:
        print(f"DRY RUN ({'offline' if api.offline else 'reads from App Store Connect'}): nothing is written.\n")

    steps = {
        "metadata": [("metadata", lambda: cmd_metadata(ctx, parse_langs(args.langs)))],
        "screenshots": [("screenshots", lambda: cmd_screenshots(ctx, parse_langs(args.langs), True, not args.skip_previews))],
        "previews": [("previews", lambda: cmd_screenshots(ctx, parse_langs(args.langs), False, True))],
        "iap": [("iap", lambda: cmd_iap(ctx))],
        "all": [("metadata", lambda: cmd_metadata(ctx, parse_langs(args.langs))),
                ("screenshots", lambda: cmd_screenshots(ctx, parse_langs(args.langs), True, False)),
                ("previews", lambda: cmd_screenshots(ctx, parse_langs(args.langs), False, True)),
                ("iap", lambda: cmd_iap(ctx))],
    }
    if args.cmd == "status":
        try:
            cmd_status(ctx)
            return 0
        except (StepFailed, ApiError) as e:
            print(f"error: {e}", file=sys.stderr)
            return 1
    api.before_first_write = lambda: confirm(args, f"'{args.cmd}' changes for {cfg['bundleId']}")
    reports, failed = [], None
    for name, fn in steps[args.cmd]:
        print(f"\n===== {name} {'(dry run)' if args.dry_run else ''} =====")
        try:
            reports.append(fn())
        except (StepFailed, ApiError, FileError, CredentialsError, SystemExit) as e:
            failed = (name, e)
            break
    print("\n===== summary =====")
    for r in reports:
        print("  " + r.line())
        for w in r.warnings:
            print(f"     ! {w}")
    if api.writes:
        print(f"  {'planned' if args.dry_run else 'sent'} writes: {len(api.writes)} "
              f"({', '.join(f'{m} {n}' for m, n in _count_methods(api.writes))})")
    if failed:
        print(f"  FAILED at {failed[0]}: {failed[1]}", file=sys.stderr)
        return 1
    print("  Nothing was submitted for review; that stays in App Store Connect.")
    return 0


def _count_methods(writes):
    c = {}
    for m, _p, _b in writes:
        c[m] = c.get(m, 0) + 1
    return sorted(c.items())


if __name__ == "__main__":
    sys.exit(main())
