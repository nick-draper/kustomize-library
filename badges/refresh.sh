#!/bin/bash
# Refresh the SVG files in this directory from manifest.tsv.
# Run this while online, from any working directory. Commit the SVGs.
# Later README renders use those files and do not call img.shields.io.
set -euo pipefail

cd "$(dirname "$0")"

python3 - <<'PY'
import csv
import pathlib
import urllib.parse
import urllib.request

root = pathlib.Path(".")
request = urllib.request.Request(
    "https://img.shields.io/",
    headers={"User-Agent": "kustomize-library-badge-mirror"},
)

with root.joinpath("manifest.tsv").open(newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))

if not rows:
    raise SystemExit("manifest.tsv has no badges")

for row in rows:
    params = {
        "label": row["label"],
        "message": row["message"],
        "color": row["color"],
    }
    if row["logo"]:
        params["logo"] = row["logo"]
    if row["logoColor"]:
        params["logoColor"] = row["logoColor"]
    url = "https://img.shields.io/static/v1?" + urllib.parse.urlencode(params)
    request.full_url = url
    with urllib.request.urlopen(request, timeout=30) as response:
        body = response.read()
        content_type = response.headers.get("Content-Type", "")
    if "image/svg+xml" not in content_type or not body.startswith(b"<svg"):
        raise SystemExit(f"{row['file']}: shields returned {content_type or 'an empty body'}")
    text = body.decode("utf-8")
    remote = text.replace("http://www.w3.org/2000/svg", "")
    if "http://" in remote or "https://" in remote:
        raise SystemExit(f"{row['file']}: SVG still points at a remote address")
    root.joinpath(row["file"]).write_bytes(body)
    print(f"wrote {row['file']}")
PY
