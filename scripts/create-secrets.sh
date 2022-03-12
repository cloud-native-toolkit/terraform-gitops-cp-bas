#!/usr/bin/env bash

NAMESPACE="$1"
DEST_DIR="$2"

export PATH="${BIN_DIR}:${PATH}"

if ! command -v kubectl 1> /dev/null 2> /dev/null; then
  echo "kubectl cli not found" >&2
  exit 1
fi

mkdir -p "${DEST_DIR}"

if [[ -z "${DB_USER}" ]] || [[ -z "${DB_PASSWORD}" ]] || [[ -z "${GRAFANA_USER}" ]] || [[ -z "${GRAFANA_PASSWORD}" ]]; then
  echo "DB_USER, DB_PASSWORD, GRAFANA_USER, and GRAFANA_PASSWORD must be provided as environment variables"
  exit 1
fi

kubectl create secret generic database-credentials \
  --from-literal="db_username=${DB_USER}" \
  --from-literal="db_password=${DB_PASSWORD}" \
  -n "${NAMESPACE}" \
  --dry-run=client \
  --output=yaml > "${DEST_DIR}/database-credentials.yaml"

kubectl create secret generic grafana-credentials \
  --from-literal="grafana_username=${GRAFANA_USER}" \
  --from-literal="grafana_password=${GRAFANA_PASSWORD}" \
  -n "${NAMESPACE}" \
  --dry-run=client \
  --output=yaml > "${DEST_DIR}/grafana-credentials.yaml"
