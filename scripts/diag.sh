#!/usr/bin/env bash
# Collect in-container diagnostics. Usage: diag.sh <out_prefix>
set -uxo pipefail
OUT="$1"
mkdir -p "$(dirname "$OUT")"
sudo docker inspect --format '{{.State.Status}} {{.State.ExitCode}} {{.State.StartedAt}}' redroid-probe > "$OUT-state.txt" 2>&1
sudo docker exec redroid-probe sh -c 'ps -A' > "$OUT-ps.txt" 2>&1
sudo docker exec redroid-probe sh -c 'ls -l /dev | grep -i -E "binder|ashmem|dri|graphics"; echo ---; mount | grep -i -E "binder|/data|/dev"' > "$OUT-dev-mount.txt" 2>&1
sudo docker exec redroid-probe sh -c 'getprop' > "$OUT-getprop.txt" 2>&1
sudo docker exec redroid-probe sh -c 'logcat -d 2>/dev/null | tail -n 600' > "$OUT-logcat-tail.txt" 2>&1
sudo docker exec redroid-probe sh -c 'logcat -d -b crash 2>/dev/null | tail -n 200' > "$OUT-logcat-crash.txt" 2>&1
sudo docker exec redroid-probe sh -c 'logcat -d 2>/dev/null | grep -i -E "fatal|died|crash|abort|avc: denied|binder|surfaceflinger|zygote|hwservicemanager|servicemanager" | tail -n 200' > "$OUT-logcat-grep.txt" 2>&1
sudo dmesg 2>/dev/null | tail -n 150 > "$OUT-dmesg.txt" || true
sudo docker stats --no-stream redroid-probe > "$OUT-stats.txt" 2>&1
true
