#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="$ROOT_DIR/.runtime"
OPENBOT_DIR="$RUNTIME_DIR/openbot"
OPENBOT_REPO="https://github.com/CopilotKit/OpenBot.git"
OPENBOT_VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/OPENBOT_VERSION")"

mkdir -p "$RUNTIME_DIR"

if [[ ! -d "$OPENBOT_DIR/.git" ]]; then
  git clone "$OPENBOT_REPO" "$OPENBOT_DIR"
fi

git -C "$OPENBOT_DIR" fetch origin

git -C "$OPENBOT_DIR" checkout --detach "$OPENBOT_VERSION"

printf 'OpenBot ready at %s\n' "$OPENBOT_DIR"
printf 'Pinned revision: %s\n' "$(git -C "$OPENBOT_DIR" rev-parse HEAD)"
printf '\nNext:\n'
printf '  1. cp %s/.env.example %s/.env\n' "$OPENBOT_DIR" "$OPENBOT_DIR"
printf '  2. configure CopilotKit/model credentials\n'
printf '  3. set TENANT_PACKAGE_DIR=%s/tenant/job-scout\n' "$ROOT_DIR"
printf '  4. run OpenBot using its scripts/start.sh\n'
