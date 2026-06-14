#!/usr/bin/env bash
set -euo pipefail

FORGEJO_URL="${FORGEJO_URL:-http://10.10.10.10:3132}"
FORGEJO_OWNER="${FORGEJO_OWNER:-david}"
FORGEJO_REPO="${FORGEJO_REPO:-audiobooth}"
FORGEJO_SSH_HOST="${FORGEJO_SSH_HOST:-moya}"
FORGEJO_USER="${FORGEJO_USER:-david}"

if [[ -n "${FORGEJO_TOKEN:-}" ]]; then
  token="$FORGEJO_TOKEN"
else
  token="$(
    ssh "$FORGEJO_SSH_HOST" "docker exec -u git forgejo forgejo admin user generate-access-token \
      -u ${FORGEJO_USER} -t mirror-sync --scopes write:repository --raw"
  )"
fi

http_code="$(
  curl -sS -o /dev/null -w "%{http_code}" -X POST \
    "${FORGEJO_URL}/api/v1/repos/${FORGEJO_OWNER}/${FORGEJO_REPO}/mirror-sync" \
    -H "Authorization: token ${token}"
)"

if [[ "$http_code" != "200" ]]; then
  echo "Forgejo mirror sync failed (HTTP ${http_code})" >&2
  exit 1
fi

echo "Forgejo mirror sync started for ${FORGEJO_OWNER}/${FORGEJO_REPO}"
