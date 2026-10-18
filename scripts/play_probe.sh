#!/usr/bin/env bash
# After boot: record Google packages, open the Play Store, screenshot. No sign-in.
# Usage: play_probe.sh <out_prefix>
set -uxo pipefail
OUT="$1"
mkdir -p "$(dirname "$OUT")"
S="adb -s 127.0.0.1:5555 shell"
{
  echo "captured=$(date -u +%FT%TZ)"
  echo "--- google packages ---"
  $S pm list packages | grep -E "com.android.vending|com.google.android.gms|com.google.android.gsf|com.google.android.gsf.login|com.android.chrome" | tr -d '\r'
  echo "--- play store ---"
  $S pm path com.android.vending | tr -d '\r'
  $S dumpsys package com.android.vending | grep -m2 -E "versionName|versionCode" | tr -d '\r'
  echo "--- gms ---"
  $S dumpsys package com.google.android.gms | grep -m2 -E "versionName|versionCode" | tr -d '\r'
  echo "--- accounts ---"
  $S dumpsys account | grep -E "Accounts: [0-9]" | tr -d '\r'
  echo "--- props ---"
  for p in ro.product.cpu.abilist ro.build.fingerprint ro.build.version.release ro.build.type ro.debuggable ro.secure ro.setupwizard.mode; do
    printf '%s=' "$p"; $S getprop "$p" | tr -d '\r'
  done
} > "$OUT-packages.txt" 2>&1
adb -s 127.0.0.1:5555 exec-out screencap -p > "$OUT-00-home.png" || true
$S am start -n com.android.vending/com.google.android.finsky.activities.MainActivity > "$OUT-am-start.txt" 2>&1 \
  || $S monkey -p com.android.vending -c android.intent.category.LAUNCHER 1 >> "$OUT-am-start.txt" 2>&1
sleep 20
adb -s 127.0.0.1:5555 exec-out screencap -p > "$OUT-01-play-20s.png" || true
$S dumpsys window 2>/dev/null | grep -m1 -E "mCurrentFocus|mFocusedApp" | tr -d '\r' > "$OUT-focus-20s.txt"
sleep 40
adb -s 127.0.0.1:5555 exec-out screencap -p > "$OUT-02-play-60s.png" || true
$S dumpsys window 2>/dev/null | grep -m1 -E "mCurrentFocus|mFocusedApp" | tr -d '\r' > "$OUT-focus-60s.txt"
$S logcat -d 2>/dev/null | grep -i -E "finsky|vending|gms|gsf|checkin|certif|integrity|DroidGuard" | tail -n 150 > "$OUT-logcat-google.txt"
$S logcat -d -b crash 2>/dev/null | tail -n 100 > "$OUT-logcat-crash.txt"
cat "$OUT-packages.txt" "$OUT-focus-20s.txt" "$OUT-focus-60s.txt"
true
