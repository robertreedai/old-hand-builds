#!/usr/bin/env bash
# Run after `gh auth login`. Publishes to https://<user>.github.io/old-hand-builds/
set -euo pipefail
cd "$(dirname "$0")"
U=$(gh api user -q .login); R=old-hand-builds
gh repo view "$U/$R" >/dev/null 2>&1 || gh repo create "$U/$R" --public -d "Static builds"
[ -d .git ] || { git init -q -b main; git remote add origin "https://github.com/$U/$R.git"; }
gh auth setup-git
git add index.html handoff-bot/index.html && git -c user.name="$U" -c user.email="$U@users.noreply.github.com" commit -qm "Update builds" || true
git push -u origin main
gh api "repos/$U/$R/pages" >/dev/null 2>&1 || gh api "repos/$U/$R/pages" -X POST -f 'source[branch]=main' -f 'source[path]=/'
URL="https://$U.github.io/$R/handoff-bot/"
for i in $(seq 1 60); do c=$(curl -s -o /dev/null -w '%{http_code}' "$URL"); [ "$c" = 200 ] && { echo "LIVE: $URL"; exit 0; }; sleep 10; done
echo "Not live yet: $URL"; exit 1
