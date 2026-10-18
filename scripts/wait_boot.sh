#!/usr/bin/env bash
# Poll sys.boot_completed every 30 s up to a timeout, then dump evidence.
# Usage: wait_boot.sh <timeout_seconds> <out_prefix>
set -uxo pipefail
TIMEOUT="$1"
OUT="$2"
mkdir -p "$(dirname "$OUT")"
start=$(date +%s)
echo "wait_start=$(date -u +%FT%TZ)" > "$OUT-timing.txt"
booted=0
while :; do
  adb connect 127.0.0.1:5555 >/dev/null 2>&1 || true
  val=$(adb -s 127.0.0.1:5555 shell getprop sys.boot_completed 2>/dev/null | tr -d '\r\n')
  now=$(date +%s)
  echo "t+$((now-start))s boot_completed='${val}'" | tee -a "$OUT-timing.txt"
  if [ "$val" = "1" ]; then booted=1; break; fi
  if [ $((now-start)) -ge "$TIMEOUT" ]; then break; fi
  sleep 30
done
echo "booted=$booted elapsed=$(( $(date +%s)-start ))s" | tee -a "$OUT-timing.txt"
if [ "$booted" = "1" ]; then
  for p in ro.product.cpu.abilist ro.build.fingerprint ro.build.version.release ro.build.version.security_patch ro.build.type ro.debuggable ro.secure ro.hardware; do
    printf '%s=' "$p"; adb -s 127.0.0.1:5555 shell getprop "$p" | tr -d '\r'
  done | tee "$OUT-props.txt"
  adb -s 127.0.0.1:5555 shell wm size | tee "$OUT-wm.txt"
  adb -s 127.0.0.1:5555 shell dumpsys SurfaceFlinger 2>/dev/null | head -40 > "$OUT-surfaceflinger.txt"
  adb -s 127.0.0.1:5555 exec-out screencap -p > "$OUT-screen.png" || true
  ls -l "$OUT-screen.png" || true
fi
sudo docker stats --no-stream redroid-probe | tee "$OUT-stats.txt"
sudo docker logs --tail 100 redroid-probe > "$OUT-container-log.txt" 2>&1 || true
[ "$booted" = "1" ]
