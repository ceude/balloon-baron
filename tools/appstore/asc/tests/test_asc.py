"""Offline tests: python3 -m unittest discover -s tools/appstore/asc/tests -v"""
import ast
import glob
import hashlib
import io
import json
import logging
import os
import struct
import sys
import tempfile
import time
import unittest
import zlib
from contextlib import redirect_stderr, redirect_stdout
from types import SimpleNamespace

HERE = os.path.dirname(os.path.abspath(__file__))
TOOL = os.path.dirname(HERE)
ROOT = os.path.abspath(os.path.join(TOOL, "..", "..", ".."))
sys.path.insert(0, TOOL)

import asc  # noqa: E402
import asc_client  # noqa: E402
from asc_files import (FileError, check_preview_probe, check_text_fields, check_upload_operations, load_iap,  # noqa: E402
                       md5_file, parse_asc_blocks, parse_legacy_v2, parse_metadata_md, plan_chunks, png_info, read_chunk)


def make_png(path, w, h, color_type=2):
    """A tiny valid PNG (8-bit RGB or RGBA)."""
    ch = {2: 3, 6: 4}[color_type]
    raw = b"".join(b"\x00" + bytes([200]) * (w * ch) for _ in range(h))

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, color_type, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


class MetadataFormat(unittest.TestCase):
    MD = """# Notes, anything goes here

```asc:name
Balon Baronu: Kapadokya
```

```asc:subtitle
Sıcak Hava Balonu Tycoon Oyunu
```

```asc:keywords
idle,işletme,simülasyon
```

```asc:promotionalText
Tek bir sepetle başla.
```

```asc:description
Birinci paragraf.

İKİNCİ BAŞLIK
• madde
```
"""

    def test_blocks(self):
        m = parse_metadata_md(self.MD)
        self.assertEqual(m.layout, "blocks")
        self.assertEqual(m.fields["name"], "Balon Baronu: Kapadokya")
        self.assertEqual(m.fields["description"], "Birinci paragraf.\n\nİKİNCİ BAŞLIK\n• madde")
        self.assertEqual(check_text_fields(m.fields)[0], [])

    def test_strict_errors(self):
        with self.assertRaises(FileError):
            parse_asc_blocks("```asc:nmae\nx\n```\n")  # unknown field
        with self.assertRaises(FileError):
            parse_asc_blocks("```asc:name\nA\n```\n```asc:name\nB\n```\n")  # twice
        with self.assertRaises(FileError):
            parse_asc_blocks("```asc:description\nnever closed\n")
        with self.assertRaises(FileError):
            parse_asc_blocks("```asc:subtitle\nline one\nline two\n```\n")  # single-line field
        with self.assertRaises(FileError):
            parse_metadata_md("# nothing machine readable\n")

    def test_tilde_fence_and_crlf(self):
        f = parse_asc_blocks("~~~asc:name\r\nAd\r\n~~~\r\n")
        self.assertEqual(f, {"name": "Ad"})

    def test_legacy_tr_v2(self):
        path = os.path.join(ROOT, "marketing", "appstore", "tr-v2", "metadata-tr.md")
        if not os.path.isfile(path):
            self.skipTest("no tr-v2 metadata in this checkout")
        m = parse_metadata_md(open(path, encoding="utf-8").read())
        self.assertEqual(m.layout, "legacy-v2")
        f = m.fields
        self.assertEqual(f["name"], "Balon Baronu: Kapadokya")
        self.assertEqual(len(f["subtitle"]), 30)
        self.assertNotIn("`", f["keywords"])
        self.assertTrue(f["description"].startswith("Kapadokya"))
        self.assertFalse(f["description"].endswith("```"))
        errors, _ = check_text_fields(f)
        self.assertEqual(errors, [])

    def test_legacy_table(self):
        md = "| Alan | Metin |\n|---|---|\n| Ad (TR) | Ad Bir | 6 |\n| Alt başlık | Alt | 3 |\n" \
             "| Anahtar kelimeler | `a,b` | 3 |\n\n## Tanıtım metni (170)\n\n> Satır bir\n> satır iki\n\nNot.\n\n" \
             "## Açıklama\n\n```\nMetin\n```\n"
        self.assertEqual(parse_legacy_v2(md), {"name": "Ad Bir", "subtitle": "Alt", "keywords": "a,b",
                                               "promotionalText": "Satır bir satır iki", "description": "Metin"})


class Limits(unittest.TestCase):
    def base(self, **kw):
        f = {"name": "Name", "subtitle": "Sub", "keywords": "a,b", "promotionalText": "P", "description": "D"}
        f.update(kw)
        return check_text_fields(f)

    def test_limits(self):
        self.assertEqual(self.base()[0], [])
        self.assertEqual(self.base(name="x" * 30)[0], [])
        self.assertIn("name: 31 characters, limit 30", self.base(name="x" * 31)[0])
        self.assertTrue(self.base(subtitle="x" * 31)[0])
        self.assertTrue(self.base(keywords="k" * 101)[0])
        self.assertEqual(self.base(keywords="k" * 100)[0], [])
        self.assertTrue(self.base(promotionalText="p" * 171)[0])
        self.assertTrue(self.base(description="d" * 4001)[0])
        self.assertEqual(self.base(description="ç" * 4000)[0], [])  # characters, not bytes

    def test_missing_and_urls(self):
        self.assertIn("subtitle: missing", check_text_fields({"name": "x"})[0])
        self.assertTrue(self.base(supportUrl="ftp://x")[0])
        self.assertEqual(self.base(supportUrl="https://example.com/s")[0], [])

    def test_keyword_warnings(self):
        err, warn = self.base(name="Balon Baronu", keywords="balon, pilot,pilot")
        self.assertEqual(err, [])
        text = " ".join(warn)
        self.assertIn("spaces", text)
        self.assertIn("repeated", text)
        self.assertIn("already in the name", text)
        self.assertTrue(self.base(keywords="a,,b")[0])


class FilesAndChunks(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.d = self.tmp.name

    def tearDown(self):
        self.tmp.cleanup()

    def test_png(self):
        p = os.path.join(self.d, "a.png")
        make_png(p, 13, 7)
        self.assertEqual(png_info(p), (13, 7, False))
        make_png(p, 4, 5, color_type=6)
        self.assertEqual(png_info(p), (4, 5, True))
        with open(p, "wb") as f:
            f.write(b"GIF89a....")
        with self.assertRaises(FileError):
            png_info(p)

    def test_md5(self):
        p = os.path.join(self.d, "b.bin")
        data = os.urandom(3 * 1024 * 1024 + 17)
        open(p, "wb").write(data)
        self.assertEqual(md5_file(p, block=4096), hashlib.md5(data).hexdigest())

    def test_chunks(self):
        self.assertEqual(plan_chunks(0, 5), [])
        self.assertEqual(plan_chunks(10, 5), [(0, 5), (5, 5)])
        self.assertEqual(plan_chunks(11, 5), [(0, 5), (5, 5), (10, 1)])
        p = os.path.join(self.d, "c.bin")
        data = bytes(range(256)) * 41
        open(p, "wb").write(data)
        ops = [{"offset": o, "length": n} for o, n in plan_chunks(len(data), 1000)]
        check_upload_operations(ops, len(data))
        self.assertEqual(b"".join(read_chunk(p, o["offset"], o["length"]) for o in ops), data)
        check_upload_operations(list(reversed(ops)), len(data))  # order of the list doesn't matter
        with self.assertRaises(FileError):
            check_upload_operations(ops[:-1], len(data))  # short
        with self.assertRaises(FileError):
            check_upload_operations([ops[0], ops[2]] + ops[3:], len(data))  # gap
        with self.assertRaises(FileError):
            check_upload_operations(ops + [{"offset": 0, "length": 1}], len(data))  # overlap
        with self.assertRaises(FileError):
            check_upload_operations([], len(data))
        with self.assertRaises(FileError):
            read_chunk(p, len(data) - 2, 10)

    def test_preview_probe(self):
        ok = {"streams": [{"codec_type": "video", "codec_name": "h264", "width": 886, "height": 1920,
                           "avg_frame_rate": "30/1"},
                          {"codec_type": "audio", "codec_name": "aac", "channels": 2, "sample_rate": "48000"}],
              "format": {"duration": "25.1", "size": "35000000"}}
        info, problems = check_preview_probe(ok, [[886, 1920]])
        self.assertEqual(problems, [])
        self.assertEqual(info["fps"], 30.0)
        bad = json.loads(json.dumps(ok))
        bad["streams"][0].update(width=1080, avg_frame_rate="60/1", codec_name="hevc")
        bad["streams"].pop()
        bad["format"]["duration"] = "40"
        _, problems = check_preview_probe(bad, [[886, 1920]])
        self.assertEqual(len(problems), 5)


class Jwt(unittest.TestCase):
    def key(self):
        from cryptography.hazmat.primitives import serialization
        from cryptography.hazmat.primitives.asymmetric import ec
        k = ec.generate_private_key(ec.SECP256R1())
        pem = k.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                              serialization.NoEncryption()).decode()
        return k, pem

    def test_token(self):
        import jwt
        k, pem = self.key()
        creds = asc_client.Credentials("ABC123DEFG", "69a6de70-0000-47e3-e053-5b8c7c11a4d1", pem)
        now = time.time()
        tok, exp = asc_client.make_token(creds, now)
        self.assertEqual(jwt.get_unverified_header(tok), {"alg": "ES256", "kid": "ABC123DEFG", "typ": "JWT"})
        claims = jwt.decode(tok, k.public_key(), algorithms=["ES256"], audience="appstoreconnect-v1")
        self.assertEqual(claims["iss"], creds.issuer_id)
        self.assertEqual(claims["exp"] - claims["iat"], 20 * 60)
        self.assertLessEqual(claims["exp"], now + 20 * 60)
        self.assertEqual(exp, claims["exp"])

    def test_env(self):
        _, pem = self.key()
        env = {"ASC_KEY_ID": "K", "ASC_ISSUER_ID": "I", "ASC_KEY_P8": pem.replace("\n", "\\n")}
        c = asc_client.Credentials.from_env(env)
        self.assertTrue(c.private_key.startswith("-----BEGIN PRIVATE KEY-----\n"))
        with tempfile.NamedTemporaryFile("w", suffix=".p8", delete=False) as f:
            f.write(pem)
        try:
            c = asc_client.Credentials.from_env({"ASC_KEY_ID": "K", "ASC_ISSUER_ID": "I", "ASC_KEY_P8_PATH": f.name})
            self.assertIn("PRIVATE KEY", c.private_key)
        finally:
            os.unlink(f.name)
        with self.assertRaises(asc_client.CredentialsError):
            asc_client.Credentials.from_env({"ASC_KEY_ID": "K"})
        with self.assertRaises(asc_client.CredentialsError):
            asc_client.Credentials.from_env({"ASC_KEY_ID": "K", "ASC_ISSUER_ID": "I", "ASC_KEY_P8_PATH": "/nope.p8"})


class FakeResponse:
    def __init__(self, status, body=None, headers=None):
        self.status_code, self.headers = status, headers or {}
        self.content = json.dumps(body).encode() if body is not None else b""
        self.text = self.content.decode()

    def json(self):
        return json.loads(self.content)


class FakeSession:
    def __init__(self, responses):
        self.responses, self.calls = list(responses), []

    def request(self, method, url, **kw):
        self.calls.append((method, url, kw))
        r = self.responses.pop(0)
        if isinstance(r, Exception):
            raise r
        return r


class Retries(unittest.TestCase):
    def api(self, responses):
        _, pem = Jwt().key()
        creds = asc_client.Credentials("K", "I", pem)
        sleeps = []
        api = asc_client.Api(creds, session=FakeSession(responses), sleep=sleeps.append)
        return api, sleeps

    def test_backoff_then_success(self):
        api, sleeps = self.api([FakeResponse(429, {}, {"Retry-After": "3"}), FakeResponse(503, {}),
                                ConnectionError("reset"), FakeResponse(200, {"data": {"id": "1"}})])
        self.assertEqual(api.request("GET", "/v1/apps")["data"]["id"], "1")
        self.assertEqual(sleeps[0], 3.0)
        self.assertEqual(len(sleeps), 3)

    def test_gives_up(self):
        api, _ = self.api([FakeResponse(500, {})] * 6)
        with self.assertRaises(asc_client.ApiError):
            api.request("GET", "/v1/apps")

    def test_401_refreshes_once(self):
        api, _ = self.api([FakeResponse(401, {}), FakeResponse(200, {"data": []})])
        api.request("GET", "/v1/apps")
        a1 = api.session.calls[0][2]["headers"]["Authorization"]
        self.assertTrue(a1.startswith("Bearer "))
        api2, _ = self.api([FakeResponse(401, {}), FakeResponse(401, {"errors": [{"code": "NOT_AUTHORIZED"}]})])
        with self.assertRaises(asc_client.ApiError) as e:
            api2.request("GET", "/v1/apps")
        self.assertEqual(e.exception.status, 401)

    def test_error_detail_and_404(self):
        api, _ = self.api([FakeResponse(409, {"errors": [{"code": "ENTITY_ERROR", "title": "t", "detail": "d"}]}),
                           FakeResponse(404, {})])
        with self.assertRaises(asc_client.ApiError) as e:
            api.request("POST", "/v1/x", body={})
        self.assertIn("ENTITY_ERROR", str(e.exception))
        self.assertIsNone(api.get_one("/v1/missing"))

    def test_paging(self):
        api, _ = self.api([FakeResponse(200, {"data": [{"id": "1"}], "links": {"next": "https://x/next"}}),
                           FakeResponse(200, {"data": [{"id": "2"}], "links": {}})])
        self.assertEqual([d["id"] for d in api.get_all("/v1/apps")], ["1", "2"])
        self.assertEqual(api.session.calls[1][1], "https://x/next")

    def test_upload_chunks(self):
        with tempfile.NamedTemporaryFile(delete=False) as f:
            f.write(b"abcdefghij")
        try:
            api, _ = self.api([FakeResponse(200), FakeResponse(503), FakeResponse(200)])
            ops = [{"method": "PUT", "url": "u1", "offset": 0, "length": 6, "requestHeaders": [{"name": "H", "value": "1"}]},
                   {"method": "PUT", "url": "u2", "offset": 6, "length": 4, "requestHeaders": []}]
            api.upload(f.name, 10, ops)
            calls = api.session.calls
            self.assertEqual([(c[1], c[2]["data"]) for c in calls], [("u1", b"abcdef"), ("u2", b"ghij"), ("u2", b"ghij")])
            self.assertEqual(calls[0][2]["headers"], {"H": "1"})
            self.assertNotIn("Authorization", calls[0][2]["headers"])
        finally:
            os.unlink(f.name)

    def test_dry_run_never_sends(self):
        api, _ = self.api([])
        api.dry_run = True
        with redirect_stdout(io.StringIO()) as out:
            r = api.post("/v1/appScreenshotSets", {"data": {"type": "appScreenshotSets"}})
            api.delete("/v1/appScreenshots/1")
        self.assertTrue(r["data"]["id"].startswith("dry-appScreenshotSets-"))
        self.assertEqual(api.session.calls, [])
        self.assertIn("DRY-RUN DELETE /v1/appScreenshots/1", out.getvalue())

    def test_offline_needs_dry_run(self):
        with self.assertRaises(asc_client.CredentialsError):
            asc_client.Api(None, dry_run=False)


class IapData(unittest.TestCase):
    def test_iap_json(self):
        prods, errors = load_iap(os.path.join(TOOL, "iap.json"), asc.ALL_LANGS)
        self.assertEqual(errors, [])
        self.assertEqual(len(prods), 15)
        for p in prods:
            self.assertTrue(os.path.isfile(os.path.join(TOOL, p["reviewScreenshot"])), p["reviewScreenshot"])
            w, h, alpha = png_info(os.path.join(TOOL, p["reviewScreenshot"]))
            self.assertEqual((w, h, alpha), (1290, 2796, False))

    def test_matches_storekit_and_game_names(self):
        sk_path = os.path.join(ROOT, "StoreKit", "BalloonBaron.storekit")
        if not os.path.isfile(sk_path):
            self.skipTest("no StoreKit file")
        sk = {p["productID"]: p["displayPrice"] for p in json.load(open(sk_path))["products"]}
        prods, _ = load_iap(os.path.join(TOOL, "iap.json"), asc.ALL_LANGS)
        self.assertEqual({p["productId"]: p["price"] for p in prods}, sk)
        strings = {}
        for f in glob.glob(os.path.join(ROOT, "tools", "strings", "*.py")):
            for line in open(f, encoding="utf-8"):
                line = line.strip()
                if line.startswith('add("store.'):
                    a = ast.literal_eval(line[3:])
                    strings[a[0]] = a[1:7]
        keys = {"decorpack": "decorPack", "figurepack": "figurePack", "worldtour": "worldTour"}
        for p in prods:
            s = p["productId"].split(".", 1)[1]
            game = strings["store." + keys.get(s, s)]
            order = ["en", "tr", "de", "es", "ja", "ko"]  # the argument order of add() in tools/strings
            self.assertEqual([p["localizations"][l]["name"] for l in order], list(game), p["productId"])


class FakeApi(asc_client.Api):
    """Dry-run Api whose reads come from a route table, so the idempotency logic can be checked offline."""

    def __init__(self, routes):
        super().__init__(asc_client.Credentials("K", "I", "x"), dry_run=True, session=object())
        self.routes = routes

    def get_all(self, path, params=None, with_included=False):
        d = self.routes.get(path, [])
        return (d, []) if with_included else d

    def get_one(self, path, params=None):
        return self.routes.get(path)


def ctx_with(routes, **args):
    cfg = json.load(open(os.path.join(TOOL, "config.json")))
    a = SimpleNamespace(overwrite=False, base_territory=None, extra_locales=False, **args)
    return asc.Ctx(FakeApi(routes), cfg, ROOT, a)


class Idempotency(unittest.TestCase):
    def test_screenshot_set_unchanged_and_reordered(self):
        from asc_files import Asset
        assets = [Asset(f"/x/{i:02}.png", 10, f"md5-{i}") for i in (1, 2, 3)]
        shot = lambda i, m: {"id": f"s{i}", "attributes": {"sourceFileChecksum": m, "assetDeliveryState": {"state": "COMPLETE"}}}
        routes = {"/v1/appStoreVersionLocalizations/L/appScreenshotSets":
                  [{"id": "SET", "attributes": {"screenshotDisplayType": "APP_IPHONE_67"}}],
                  "/v1/appScreenshotSets/SET/appScreenshots": [shot(1, "md5-1"), shot(2, "md5-2"), shot(3, "md5-3")]}
        ctx = ctx_with(routes)
        rep = asc.Report("t")
        with redirect_stdout(io.StringIO()):
            asc.sync_screenshot_set(ctx, rep, "L", "APP_IPHONE_67", assets)
        self.assertEqual(ctx.api.writes, [])
        routes["/v1/appScreenshotSets/SET/appScreenshots"] = [shot(3, "md5-3"), shot(1, "md5-1"), shot(2, "md5-2")]
        with redirect_stdout(io.StringIO()):
            asc.sync_screenshot_set(ctx, rep, "L", "APP_IPHONE_67", assets)
        self.assertEqual([(m, p) for m, p, _ in ctx.api.writes], [("PATCH", "/v1/appScreenshotSets/SET/relationships/appScreenshots")])
        self.assertEqual([d["id"] for d in ctx.api.writes[0][2]["data"]], ["s1", "s2", "s3"])

    def test_screenshot_set_replaced(self):
        from asc_files import Asset
        assets = [Asset("/x/01.png", 10, "new")]
        routes = {"/v1/appStoreVersionLocalizations/L/appScreenshotSets":
                  [{"id": "SET", "attributes": {"screenshotDisplayType": "APP_IPHONE_67"}}],
                  "/v1/appScreenshotSets/SET/appScreenshots":
                  [{"id": "old", "attributes": {"fileName": "a.png", "sourceFileChecksum": "x",
                                                "assetDeliveryState": {"state": "COMPLETE"}}}]}
        ctx = ctx_with(routes)
        with redirect_stdout(io.StringIO()):
            asc.sync_screenshot_set(ctx, asc.Report("t"), "L", "APP_IPHONE_67", assets)
        self.assertEqual([(m, p) for m, p, _ in ctx.api.writes],
                         [("DELETE", "/v1/appScreenshots/old"), ("POST", "/v1/appScreenshots"),
                          ("PATCH", "/v1/appScreenshots/dry-appScreenshots-1"),
                          ("PATCH", "/v1/appScreenshotSets/SET/relationships/appScreenshots")])
        self.assertEqual(ctx.api.writes[2][2]["data"]["attributes"], {"uploaded": True, "sourceFileChecksum": "new"})

    def test_metadata_patch_only_changes(self):
        ctx = ctx_with({})
        rep = asc.Report("t")
        existing = {"tr": {"id": "LOC", "attributes": {"locale": "tr", "description": "same", "keywords": "old"}}}
        with redirect_stdout(io.StringIO()):
            asc.upsert_localization(ctx, rep, existing, "tr", {"description": "same", "keywords": "new", "supportUrl": None},
                                    "appStoreVersionLocalizations", "appStoreVersion", "appStoreVersions", "V")
            asc.upsert_localization(ctx, rep, existing, "tr", {"description": "same", "keywords": "old"},
                                    "appStoreVersionLocalizations", "appStoreVersion", "appStoreVersions", "V")
        self.assertEqual(len(ctx.api.writes), 1)
        self.assertEqual(ctx.api.writes[0][2]["data"]["attributes"], {"keywords": "new"})

    def test_existing_iap_is_only_filled(self):
        prods, _ = load_iap(os.path.join(TOOL, "iap.json"), asc.ALL_LANGS)
        p = next(x for x in prods if x["productId"] == "balloonbaron.gold")
        locs = [{"id": f"l{i}", "attributes": {"locale": loc, **p["localizations"][lang]}}
                for i, (lang, loc) in enumerate([("tr", "tr"), ("en", "en-US")])]
        locs[0]["attributes"]["name"] = "Varak altın"  # typed by hand, differs from the game
        routes = {"/v2/inAppPurchases/G/inAppPurchaseLocalizations": locs}
        ctx = ctx_with(routes)
        rep = asc.Report("t")
        existing = {"balloonbaron.gold": {"id": "G", "attributes": {"productId": "balloonbaron.gold", "name": "Gold",
                                                                    "inAppPurchaseType": "NON_CONSUMABLE",
                                                                    "state": "MISSING_METADATA", "familySharable": False}}}
        with redirect_stdout(io.StringIO()):
            iap_id, ok = asc.ensure_iap(ctx, rep, "APP", existing, p)
            asc.ensure_iap_localizations(ctx, rep, iap_id, p)
        writes = [(m, pth, b["data"].get("attributes")) for m, pth, b in ctx.api.writes]
        self.assertEqual(writes[0][:2], ("PATCH", "/v2/inAppPurchases/G"))
        self.assertEqual(set(writes[0][2]), {"reviewNote"})  # reference name kept, review note filled
        created = [w[2]["locale"] for w in writes[1:]]
        self.assertEqual(created, ["de-DE", "es-ES", "ja", "ko"])  # tr and en-US exist; tr's hand-typed name is kept
        self.assertTrue(any("Varak altın" in w for w in rep.warnings))

    def test_wrong_iap_type_stops(self):
        prods, _ = load_iap(os.path.join(TOOL, "iap.json"), asc.ALL_LANGS)
        ctx = ctx_with({})
        existing = {prods[0]["productId"]: {"id": "X", "attributes": {"inAppPurchaseType": "CONSUMABLE"}}}
        with self.assertRaises(asc.StepFailed), redirect_stdout(io.StringIO()):
            asc.ensure_iap(ctx, asc.Report("t"), "APP", existing, prods[0])

    def test_price_unchanged(self):
        ctx = ctx_with({"/v2/inAppPurchases/G/iapPriceSchedule": {"id": "S"},
                        "/v1/inAppPurchasePriceSchedules/S/baseTerritory": {"id": "DEU"}})
        ctx.api.get_all = lambda path, params=None, with_included=False: (
            [{"id": "p", "attributes": {}, "relationships": {"territory": {"data": {"id": "DEU"}},
                                                             "inAppPurchasePricePoint": {"data": {"id": "PP"}}}}],
            [{"type": "inAppPurchasePricePoints", "id": "PP", "attributes": {"customerPrice": "0.99"}}])
        rep = asc.Report("t")
        asc.ensure_price(ctx, rep, "G", {"productId": "balloonbaron.gold", "price": "0.99"}, "DEU")
        self.assertEqual(ctx.api.writes, [])
        self.assertEqual(rep.counts, {"prices unchanged": 1})


class Cli(unittest.TestCase):
    def test_offline_dry_runs(self):
        env = {k: os.environ.pop(k) for k in list(os.environ) if k.startswith("ASC_")}
        try:
            for argv in (["iap", "--dry-run"], ["metadata", "--langs", "tr,ko", "--dry-run"],
                         ["screenshots", "--langs", "ko", "--dry-run"]):
                with redirect_stdout(io.StringIO()) as out:
                    code = asc.main(argv)
                self.assertEqual(code, 0, out.getvalue()[-2000:])
                self.assertIn("Nothing was submitted", out.getvalue())
        finally:
            os.environ.update(env)

    def test_write_needs_credentials(self):
        env = {k: os.environ.pop(k) for k in list(os.environ) if k.startswith("ASC_")}
        try:
            with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
                self.assertEqual(asc.main(["iap", "--yes"]), 2)
        finally:
            os.environ.update(env)


def setUpModule():
    logging.disable(logging.CRITICAL)  # the retry warnings are expected here


def tearDownModule():
    logging.disable(logging.NOTSET)


if __name__ == "__main__":
    unittest.main()
