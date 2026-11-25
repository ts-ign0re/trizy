#!/bin/sh
# Builds the release archive from the committed HEAD: OUT/trizy.tar.gz (top directory trizy/) and its .sha256.
# The release workflow runs it on a tag; install.sh downloads exactly these two files.
set -eu
out=${1:?usage: scripts/package.sh OUTDIR}
mkdir -p "$out"
git archive --format=tar --prefix=trizy/ HEAD | gzip -n >"$out/trizy.tar.gz"
cd "$out"
if command -v sha256sum >/dev/null 2>&1; then sha256sum trizy.tar.gz >trizy.tar.gz.sha256
else shasum -a 256 trizy.tar.gz >trizy.tar.gz.sha256; fi
