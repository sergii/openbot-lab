#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENBOT_DIR="$ROOT_DIR/.runtime/openbot"
ENV_FILE="$OPENBOT_DIR/.env"

failures=0

docker_ready=false

ok() {
  printf 'OK   %s\n' "$1"
}

warn() {
  printf 'WARN %s\n' "$1"
}

fail() {
  printf 'FAIL %s\n' "$1"
  failures=$((failures + 1))
}

printf 'OpenBot Lab doctor\n==================\n'

if command -v git >/dev/null 2>&1; then
  ok "git: $(git --version)"
else
  fail "git is not installed"
fi

if command -v node >/dev/null 2>&1; then
  ok "node: $(node --version)"
else
  fail "node is not installed"
fi

if command -v bun >/dev/null 2>&1; then
  ok "bun: $(bun --version)"
else
  fail "bun is not installed - install it from https://bun.sh"
fi

if command -v docker >/dev/null 2>&1; then
  ok "docker CLI: $(docker --version)"
  if docker info >/dev/null 2>&1; then
    docker_ready=true
    ok "docker daemon is reachable"
  else
    context="$(docker context show 2>/dev/null || true)"
    fail "docker daemon is not reachable${context:+ (context: $context)}"
  fi
else
  fail "docker CLI is not installed"
fi

if [[ -d "$OPENBOT_DIR/.git" ]]; then
  ok "OpenBot checkout exists"
else
  fail "OpenBot checkout missing - run ./scripts/bootstrap-openbot.sh"
fi

if [[ -f "$ENV_FILE" ]]; then
  ok ".env exists"

  required=(
    INTELLIGENCE_API_URL
    INTELLIGENCE_GATEWAY_WS_URL
    INTELLIGENCE_API_KEY
    COPILOTKIT_LICENSE_TOKEN
    OPENAI_API_KEY
    TENANT_PACKAGE_DIR
  )

  for key in "${required[@]}"; do
    value="$(sed -n "s/^${key}=//p" "$ENV_FILE" | tail -n 1)"
    if [[ -n "$value" ]]; then
      if [[ "$key" == "TENANT_PACKAGE_DIR" ]]; then
        if [[ -d "$value" ]]; then
          ok "$key=$value"
        else
          fail "$key points to a missing directory: $value"
        fi
      else
        ok "$key=<configured>"
      fi
    else
      fail "$key is missing or empty"
    fi
  done

  cpk_key="$(sed -n 's/^CPK_INTELLIGENCE_API_KEY=//p' "$ENV_FILE" | tail -n 1)"
  legacy_key="$(sed -n 's/^INTELLIGENCE_API_KEY=//p' "$ENV_FILE" | tail -n 1)"
  if [[ -n "$cpk_key" && -n "$legacy_key" && "$cpk_key" != "$legacy_key" ]]; then
    warn "CPK_INTELLIGENCE_API_KEY and INTELLIGENCE_API_KEY differ"
  fi

  postgres_port="$(sed -n 's/^POSTGRES_PORT=//p' "$ENV_FILE" | tail -n 1)"
  postgres_port="${postgres_port:-5432}"
  database_url="$(sed -n 's/^DATABASE_URL=//p' "$ENV_FILE" | tail -n 1)"

  if [[ "$database_url" == *"@localhost:"* || "$database_url" == *"@127.0.0.1:"* ]]; then
    if [[ "$database_url" != *":${postgres_port}/"* ]]; then
      fail "DATABASE_URL does not use POSTGRES_PORT=$postgres_port"
    else
      ok "DATABASE_URL matches POSTGRES_PORT=$postgres_port"
    fi

    if command -v lsof >/dev/null 2>&1 && lsof -nP -iTCP:"$postgres_port" -sTCP:LISTEN >/dev/null 2>&1; then
      openbot_postgres=false
      if [[ "$docker_ready" == true && -d "$OPENBOT_DIR" ]]; then
        container_id="$(cd "$OPENBOT_DIR" && docker compose ps -q postgres 2>/dev/null || true)"
        if [[ -n "$container_id" ]]; then
          openbot_postgres=true
        fi
      fi

      if [[ "$openbot_postgres" == true ]]; then
        ok "Postgres port $postgres_port is held by the OpenBot stack"
      else
        holder="$(lsof -nP -iTCP:"$postgres_port" -sTCP:LISTEN -Fcn 2>/dev/null | awk '/^c/{c=substr($0,2)} /^n/{print c" ("substr($0,2)")"; exit}' || true)"
        fail "Postgres port $postgres_port is already in use${holder:+ by $holder} - choose another POSTGRES_PORT and update DATABASE_URL"
      fi
    else
      ok "Postgres port $postgres_port is available"
    fi
  fi
else
  fail ".env is missing - copy .env.example to .env"
fi

printf '\n'
if (( failures > 0 )); then
  printf '%d problem(s) found.\n' "$failures"
  exit 1
fi

printf 'All preflight checks passed.\n'
