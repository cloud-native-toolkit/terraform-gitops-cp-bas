#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

NAME="$1"
CHART_DIR="$2"
DEST_DIR="$3"

mkdir -p "${DEST_DIR}"

cp -R "${CHART_DIR}"/* "${DEST_DIR}"

find "${DEST_DIR}" -name "*"
