#!/usr/bin/env bash

PIBULUS_OS_ROOT="${PIBULUS_OS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PIBULUS_OS_ENV="${PIBULUS_OS_ENV:-$PIBULUS_OS_ROOT/pibulus-os.env}"
PIBULUS_STACK_ENV="${PIBULUS_STACK_ENV:-$PIBULUS_OS_ROOT/config/stacks/.env}"

load_pibulus_env_file() {
  local env_file=$1
  [ -r "$env_file" ] || return 0
  set -a
  # shellcheck disable=SC1090
  . "$env_file"
  set +a
}

load_pibulus_env_file "$PIBULUS_OS_ENV"
load_pibulus_env_file "$PIBULUS_STACK_ENV"
