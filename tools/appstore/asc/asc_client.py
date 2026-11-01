"""App Store Connect API client: ES256 JWT, retries with backoff, paging, dry-run recording, chunked uploads."""
from __future__ import annotations

import json
import logging
import os
import random
import time
from dataclasses import dataclass

from asc_files import FileError, check_upload_operations, read_chunk

log = logging.getLogger("asc")

BASE = "https://api.appstoreconnect.apple.com"
AUDIENCE = "appstoreconnect-v1"
TOKEN_LIFETIME = 20 * 60  # Apple refuses tokens that live longer than 20 minutes
CLOCK_SKEW = 30  # iat a little in the past, so a fast local clock can't push the lifetime over 20 minutes
RETRY_STATUS = {429, 500, 502, 503, 504}


class ApiError(Exception):
    def __init__(self, status, method, path, body):
        self.status, self.method, self.path, self.body = status, method, path, body
        detail = body
        try:
            errs = json.loads(body).get("errors", [])
            detail = "; ".join(f"{e.get('code')}: {e.get('title')} — {e.get('detail')}" for e in errs) or body
        except Exception:
            pass
        super().__init__(f"{method} {path} → HTTP {status}: {detail}")


class CredentialsError(Exception):
    pass


@dataclass
class Credentials:
    key_id: str
    issuer_id: str
    private_key: str  # PEM

    @classmethod
    def from_env(cls, env=None) -> "Credentials":
        env = os.environ if env is None else env
        kid, iss = env.get("ASC_KEY_ID", "").strip(), env.get("ASC_ISSUER_ID", "").strip()
        pem = env.get("ASC_KEY_P8", "")
        path = env.get("ASC_KEY_P8_PATH", "").strip()
        if not pem and path:
            path = os.path.expanduser(path)
            if not os.path.isfile(path):
                raise CredentialsError(f"ASC_KEY_P8_PATH points to a missing file: {path}")
            with open(path, encoding="utf-8") as f:
                pem = f.read()
        pem = pem.replace("\\n", "\n").strip()  # a key pasted into one env line with literal \n
        missing = [n for n, v in (("ASC_KEY_ID", kid), ("ASC_ISSUER_ID", iss), ("ASC_KEY_P8 or ASC_KEY_P8_PATH", pem)) if not v]
        if missing:
            raise CredentialsError("missing: " + ", ".join(missing))
        if "BEGIN PRIVATE KEY" not in pem:
            raise CredentialsError("the .p8 key must be the PEM text (-----BEGIN PRIVATE KEY----- …)")
        return cls(kid, iss, pem + "\n")


def make_token(creds: Credentials, now: float | None = None) -> tuple[str, float]:
    """(jwt, expiry epoch). ES256, kid header, aud appstoreconnect-v1, 20-minute lifetime."""
    import jwt  # PyJWT (needs `cryptography` for ES256)

    now = time.time() if now is None else now
    iat = int(now) - CLOCK_SKEW
    exp = iat + TOKEN_LIFETIME
    token = jwt.encode({"iss": creds.issuer_id, "iat": iat, "exp": exp, "aud": AUDIENCE},
                       creds.private_key, algorithm="ES256", headers={"kid": creds.key_id, "typ": "JWT"})
    return token, exp


def backoff_delay(attempt: int, retry_after: str | None = None, base: float = 1.5, cap: float = 60.0) -> float:
    if retry_after:
        try:
            return min(cap, max(0.0, float(retry_after)))
        except ValueError:
            pass
    return min(cap, base * (2 ** attempt)) * (0.75 + random.random() * 0.5)


def short(body, limit=20000):
    s = json.dumps(body, ensure_ascii=False, indent=2) if not isinstance(body, str) else body
    return s if len(s) <= limit else s[:limit] + f"… ({len(s)} chars)"


class Api:
    """`dry_run`: GETs still go to Apple (when credentials exist), writes are printed and answered with fake ids.
    `offline`: no network at all (dry run without credentials): GETs return nothing, callers use placeholders."""

    def __init__(self, creds: Credentials | None, dry_run=False, offline=False, session=None, max_attempts=6,
                 sleep=time.sleep):
        self.creds, self.dry_run, self.offline = creds, dry_run, offline or creds is None
        if self.offline and not dry_run:
            raise CredentialsError("writes need credentials (ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8 / ASC_KEY_P8_PATH)")
        self.max_attempts, self.sleep = max_attempts, sleep
        self._token, self._exp = None, 0.0
        self._fake = 0
        self.writes = []  # (method, path, body) of every write, done or planned
        self.before_first_write = None  # e.g. the "Continue? [y/N]" question, asked once files are validated
        if session is None and not self.offline:
            import requests
            session = requests.Session()
            session.headers["User-Agent"] = "balloon-baron-asc/1.0"
        self.session = session

    # ---- auth
    def token(self) -> str:
        if not self._token or time.time() > self._exp - 60:
            self._token, self._exp = make_token(self.creds)
            log.debug("new JWT, expires %s", time.strftime("%H:%M:%S", time.localtime(self._exp)))
        return self._token

    # ---- raw request with retries
    def request(self, method: str, path: str, params=None, body=None, expect=(200, 201, 204)):
        url = path if path.startswith("http") else BASE + path
        refreshed = False
        for attempt in range(self.max_attempts):
            headers = {"Authorization": f"Bearer {self.token()}"}
            if body is not None:
                headers["Content-Type"] = "application/json"
            try:
                r = self.session.request(method, url, params=params, headers=headers,
                                         data=None if body is None else json.dumps(body), timeout=120)
            except Exception as e:  # connection reset, timeout, DNS…
                if attempt + 1 >= self.max_attempts:
                    raise
                d = backoff_delay(attempt)
                log.warning("%s %s: %s; retrying in %.1fs", method, path, e, d)
                self.sleep(d)
                continue
            if r.status_code == 401 and not refreshed:
                log.info("401: refreshing the token once")
                self._token, refreshed = None, True
                continue
            if r.status_code in RETRY_STATUS and attempt + 1 < self.max_attempts:
                d = backoff_delay(attempt, r.headers.get("Retry-After"))
                log.warning("%s %s → %s; retry %d/%d in %.1fs", method, path, r.status_code, attempt + 1,
                            self.max_attempts - 1, d)
                self.sleep(d)
                continue
            if r.status_code not in expect:
                raise ApiError(r.status_code, method, path, r.text)
            log.debug("%s %s → %s", method, path, r.status_code)
            return r.json() if r.content else {}
        raise ApiError(0, method, path, "gave up after retries")

    # ---- reads
    def _fake_id(self, path):
        return "dry-" in path

    def get_one(self, path, params=None):
        """The `data` object, or None when it doesn't exist (404 / empty relationship)."""
        if self.offline or self._fake_id(path):
            return None
        try:
            r = self.request("GET", path, params)
        except ApiError as e:
            if e.status == 404:
                return None
            raise
        return r.get("data")

    def get_all(self, path, params=None, with_included=False):
        """Every item of a collection, following links.next."""
        if self.offline or self._fake_id(path):
            return ([], []) if with_included else []
        params = dict(params or {})
        params.setdefault("limit", 200)
        data, included, url = [], [], path
        while url:
            try:
                r = self.request("GET", url, params)
            except ApiError as e:
                if e.status == 404:
                    break
                raise
            d = r.get("data") or []
            data.extend(d if isinstance(d, list) else [d])
            included.extend(r.get("included") or [])
            url, params = (r.get("links") or {}).get("next"), None  # next already carries the query
        return (data, included) if with_included else data

    # ---- writes
    def write(self, method, path, body=None, what=""):
        self.writes.append((method, path, body))
        if self.dry_run:
            print(f"  DRY-RUN {method} {path}" + (f"   # {what}" if what else ""))
            if body is not None:
                print("    " + short(body).replace("\n", "\n    "))
            if method == "POST":
                self._fake += 1
                t = (body or {}).get("data", {}).get("type", "x")
                return {"data": {"id": f"dry-{t}-{self._fake}", "type": t, "attributes": {}}}
            return {}
        if self.before_first_write:
            ask, self.before_first_write = self.before_first_write, None
            ask()
        log.info("%s %s%s", method, path, f"  ({what})" if what else "")
        return self.request(method, path, body=body)

    def post(self, path, body, what=""):
        return self.write("POST", path, body, what)

    def patch(self, path, body, what=""):
        return self.write("PATCH", path, body, what)

    def delete(self, path, what=""):
        return self.write("DELETE", path, None, what)

    # ---- uploads to Apple's asset servers (presigned: no JWT)
    def upload(self, path: str, size: int, ops: list):
        """Sends every uploadOperation chunk with its own method, URL and headers."""
        if self.dry_run:
            print(f"  DRY-RUN upload {os.path.basename(path)}: {len(ops) or '?'} chunk(s) to Apple's uploadOperations URLs")
            return
        check_upload_operations(ops, size)
        for n, op in enumerate(sorted(ops, key=lambda o: o["offset"]), 1):
            data = read_chunk(path, op["offset"], op["length"])
            headers = {h["name"]: h["value"] for h in op.get("requestHeaders") or []}
            for attempt in range(self.max_attempts):
                try:
                    r = self.session.request(op.get("method", "PUT"), op["url"], data=data, headers=headers, timeout=300)
                    if r.status_code < 300:
                        break
                    if r.status_code not in RETRY_STATUS:
                        raise ApiError(r.status_code, op.get("method", "PUT"), "<upload chunk>", r.text)
                    err = f"HTTP {r.status_code}"
                except ApiError:
                    raise
                except Exception as e:
                    err = str(e)
                if attempt + 1 >= self.max_attempts:
                    raise FileError(f"{os.path.basename(path)}: chunk {n} failed: {err}")
                d = backoff_delay(attempt)
                log.warning("chunk %d of %s: %s; retrying in %.1fs", n, os.path.basename(path), err, d)
                self.sleep(d)
            log.debug("chunk %d/%d of %s sent (%d bytes)", n, len(ops), os.path.basename(path), op["length"])
