#!/usr/bin/env bash
# apply.sh SRC: SRC = checkout at UPSTREAM_REF. Fail hard on any hunk failure.
set -euo pipefail
UPSTREAM_REF=eb0fb0cd49c592929e8dee83f34f7c6ac566e8d7
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=${1:?usage: apply.sh <upstream checkout>}
cd "$SRC"
[ "$(git rev-parse HEAD)" = "$(git rev-parse "$UPSTREAM_REF^{commit}")" ] || { echo "SRC not at $UPSTREAM_REF" >&2; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "SRC dirty" >&2; exit 1; }
for p in "$HERE"/patches/*.patch; do
  echo "apply $(basename "$p")"
  git apply --3way "$p" || { echo "PATCH FAILED: $p" >&2; exit 1; }
done
