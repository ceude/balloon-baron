#!/usr/bin/env bash
# Installs a Swift toolchain on Linux (cloud sessions) so the core package can be built and tested
# without a Mac. Pulls the toolchain layer of the official swift Docker image; download.swift.org
# is not reachable from every sandbox. Usage: tools/install-swift-linux.sh && export PATH=/opt/swift/usr/bin:$PATH
set -euo pipefail

TAG="${SWIFT_TAG:-6.0.3-noble}"
DEST="${SWIFT_DEST:-/opt/swift}"

if [ -x "$DEST/usr/bin/swift" ]; then
  echo "Swift already installed in $DEST"
  exit 0
fi

token() {
  curl -sS "https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/swift:pull" |
    python3 -c 'import sys, json; print(json.load(sys.stdin)["token"])'
}

TOKEN=$(token)
INDEX=$(curl -sS -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.oci.image.index.v1+json" \
  "https://registry-1.docker.io/v2/library/swift/manifests/$TAG")
DIGEST=$(python3 -c 'import sys, json
d = json.loads(sys.argv[1])
print(next(m["digest"] for m in d["manifests"] if m["platform"].get("architecture") == "amd64"))' "$INDEX")
MANIFEST=$(curl -sS -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.oci.image.manifest.v1+json" \
  "https://registry-1.docker.io/v2/library/swift/manifests/$DIGEST")
# The largest layer is the toolchain itself.
LAYER=$(python3 -c 'import sys, json
d = json.loads(sys.argv[1])
print(max(d["layers"], key=lambda l: l["size"])["digest"])' "$MANIFEST")

mkdir -p "$DEST"
echo "Downloading Swift toolchain ($TAG)…"
curl -sSL -H "Authorization: Bearer $(token)" "https://registry-1.docker.io/v2/library/swift/blobs/$LAYER" | tar xz -C "$DEST"
"$DEST/usr/bin/swift" --version
