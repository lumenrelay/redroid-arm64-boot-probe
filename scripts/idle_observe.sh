#!/usr/bin/env bash
# Sample container health every 5 minutes for N minutes; fail on lost boot state.
# Usage: idle_observe.sh <minutes> <out_prefix>
set -uxo pipefail
MINUTES="$1"
OUT="$2"
mkdir -p "$(dirname "$OUT")"
start=$(date +%s)
end=$((start + MINUTES*60))
rc=0
while :; do
  now=$(date +%s)
  ts=$(date -u +%FT%TZ)
  val=$(adb -s 127.0.0.1:5555 shell getprop sys.boot_completed 2>/dev/null | tr -d '\r\n')
  status=$(sudo docker inspect --format '{{.State.Status}}' redroid-probe 2>/dev/null)
  crashes=$(adb -s 127.0.0.1:5555 logcat -d -b crash 2>/dev/null | grep -c 'FATAL EXCEPTION\|signal [0-9]' || true)
  {
    echo "=== $ts t+$((now-start))s status=$status boot_completed=$val crash_lines=$crashes"
    sudo docker stats --no-stream redroid-probe 2>/dev/null
  } | tee -a "$OUT-samples.txt"
  if [ "$status" != "running" ] || [ "$val" != "1" ]; then rc=1; break; fi
  if [ "$now" -ge "$end" ]; then break; fi
  sleep 300
done
adb -s 127.0.0.1:5555 logcat -d -b crash 2>/dev/null | tail -n 200 > "$OUT-crash-log-tail.txt" || true
echo "idle_minutes=$MINUTES rc=$rc" | tee -a "$OUT-samples.txt"
exit $rc
