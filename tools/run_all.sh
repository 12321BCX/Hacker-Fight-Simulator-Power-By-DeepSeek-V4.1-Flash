#!/usr/bin/env bash
# Build the installer and run every check. Fails loudly if any step regresses.
set -euo pipefail
cd "$(dirname "$0")/.."

PY=tools/venv/Scripts/python
if [ ! -x "$PY" ]; then
	PY=python
fi

JAR=tools/lib/luaj-jse-3.0.1.jar
LUA="java -cp $JAR lua"

echo "== build =="
"$PY" tools/build_installer.py

rm -f tools/out/*.lua

echo "== installer dry-run =="
$LUA tools/run_installer.lua | tee /tmp/hf-installer.log >/dev/null
grep -q "installer dry-run: OK" /tmp/hf-installer.log

echo "== client smoke =="
$LUA tools/run_client_smoke.lua | tee /tmp/hf-client.log >/dev/null
grep -q "client smoke: OK" /tmp/hf-client.log

echo "== server smoke =="
$LUA tools/run_server_smoke.lua | tee /tmp/hf-server.log >/dev/null
grep -q "server smoke: OK" /tmp/hf-server.log

echo "== static verification =="
"$PY" tools/verify.py

echo
echo "ALL CHECKS PASSED"
