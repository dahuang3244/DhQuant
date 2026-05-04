#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
export PYTHONPATH="${PWD}/GUI:${PYTHONPATH:-}"
PYTHON="${PWD}/.venv/bin/python"
if [[ ! -x "$PYTHON" ]]; then
  PYTHON="python3"
fi
"$PYTHON" GUI/main.py
