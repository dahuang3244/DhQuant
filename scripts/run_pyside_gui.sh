#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
export PYTHONPATH="${PWD}/GUI:${PYTHONPATH:-}"
PYTHON="${PWD}/.venv/bin/python"
if [[ ! -x "$PYTHON" ]]; then
  python3 -m venv .venv
  PYTHON="${PWD}/.venv/bin/python"
  "$PYTHON" -m pip install --upgrade pip
  "$PYTHON" -m pip install -r requirements.txt
fi
"$PYTHON" GUI/main.py
