#!/usr/bin/env bash
set -Eeuo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

TAG="pibulus-watchdog"
REPO="/home/pibulus/pibulus-os"
COMPOSE_FILE="${REPO}/config/stacks/pirate.yml"
STATUS=0

log() {
  local message="$*"
  logger -t "${TAG}" -- "${message}"
  printf '[%s] %s\n' "$(date -u '+%Y-%m-%d %H:%M:%S UTC')" "${message}"
}

mark_failed() {
  STATUS=1
  log "ERROR: $*"
}

restart_unit_if_needed() {
  local unit="$1"

  if systemctl is-active --quiet "${unit}"; then
    log "ok: ${unit} is active"
    return 0
  fi

  log "WARN: ${unit} is not active; restarting"
  if ! systemctl restart "${unit}"; then
    mark_failed "systemctl restart ${unit} failed"
    return 1
  fi

  sleep 5
  if systemctl is-active --quiet "${unit}"; then
    log "recovered: ${unit} is active"
    return 0
  fi

  mark_failed "${unit} is still not active after restart"
  return 1
}

compose_up_if_needed() {
  local service="$1"
  local container="$2"

  if docker inspect -f '{{.State.Running}}' "${container}" 2>/dev/null | grep -qx true; then
    log "ok: container ${container} is running"
    return 0
  fi

  log "WARN: container ${container} is not running; starting compose service ${service}"
  if ! docker compose -f "${COMPOSE_FILE}" up -d "${service}"; then
    mark_failed "docker compose up ${service} failed"
    return 1
  fi

  return 0
}

http_ok() {
  local name="$1"
  local url="$2"

  if curl -fsS --connect-timeout 3 --max-time 8 "${url}" >/dev/null; then
    log "ok: ${name} responded at ${url}"
    return 0
  fi

  return 1
}

restart_compose_service_for_http() {
  local service="$1"
  local container="$2"
  local name="$3"
  local url="$4"
  local settle_seconds="${5:-8}"

  compose_up_if_needed "${service}" "${container}" || return 1

  if http_ok "${name}" "${url}"; then
    return 0
  fi

  log "WARN: ${name} did not respond; restarting compose service ${service}"
  if ! docker compose -f "${COMPOSE_FILE}" up -d --force-recreate "${service}"; then
    mark_failed "docker compose recreate ${service} failed"
    return 1
  fi

  sleep "${settle_seconds}"
  if http_ok "${name}" "${url}"; then
    log "recovered: ${name} responded after ${service} restart"
    return 0
  fi

  mark_failed "${name} still did not respond at ${url}"
  return 1
}

log "starting health pass"

restart_unit_if_needed cloudflared.service || true
restart_unit_if_needed docker.service || true

if systemctl is-active --quiet docker.service; then
  restart_compose_service_for_http web_host web_host "web host" "http://127.0.0.1/" 8 || true
  restart_compose_service_for_http jellyfin jellyfin "jellyfin" "http://127.0.0.1:8096/web/" 20 || true
else
  mark_failed "docker.service inactive; skipped container checks"
fi

if (( STATUS == 0 )); then
  log "health pass complete"
else
  log "health pass complete with failures"
fi

exit "${STATUS}"
