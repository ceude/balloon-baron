#!/bin/bash
# Captures the App Store raw screens from the real app on simulators (run by .github/workflows/store-shots.yml).
# Usage: store-shots.sh <BalloonBaron.app> <out dir>   env: LANGS, DEVICES, SCENES (empty = all), VIDEO (false / true / only)
# Scenes come from store-shots.txt next to this script.
set -u
APP=$1; OUT=$2
LIST="$(dirname "$0")/store-shots.txt"
LANGS=${LANGS:-"en tr de es ja ko fr"}; DEVICES=${DEVICES:-"iphone ipad"}; SCENES=${SCENES:-}; VIDEO=${VIDEO:-false}
BID=com.ceude.balloonbaron
SIMCTL=$(xcrun -f simctl)
mkdir -p "$OUT"

xcrun simctl list runtimes available
RUNTIME=$(xcrun simctl list runtimes available | grep -o "com.apple.CoreSimulator.SimRuntime.${RUNTIME_PREFIX:-iOS-}[0-9-]*" | sort -V | tail -n 1)
pick() { for t in "$@"; do xcrun simctl list devicetypes | grep -q "SimDeviceType.$t)" && { echo "com.apple.CoreSimulator.SimDeviceType.$t"; return; }; done; }
PHONE=$(pick iPhone-17-Pro-Max iPhone-16-Pro-Max)
case $RUNTIME in *iOS-18*) PHONE=$(pick iPhone-16-Pro-Max);; esac
IPAD=$(pick iPad-Pro-13-inch-M5-12GB iPad-Pro-13-inch-M5 iPad-Pro-13-inch-M4-8GB iPad-Pro-13-inch-M4-16GB)
echo "runtime $RUNTIME / phone $PHONE / ipad $IPAD"
# a command that may not take longer than $1 seconds (macOS has no `timeout`)
limit() { local t=$1; shift; perl -e 'alarm shift; exec @ARGV' "$t" "$@"; }
stamp() { echo "$(date +%H:%M:%S) $*"; }
# the company on screen, named in each language (the Turkish set's "Şafak Balon": "Dawn Balloon")
company_of() { case $1 in en) echo "Daybreak Balloons";; tr) echo "Şafak Balon";; de) echo "Ballon Morgenrot";; es) echo "Globos Alba";; ja) echo "あけぼの気球";; ko) echo "새벽 열기구";; fr) echo "Ballons de l’Aube";; esac; }
# a screenshot, taken again while the frame is still blank (a white launch frame compresses to a tiny PNG)
shoot() { for t in 1 2 3 4 5; do limit 30 xcrun simctl io "$1" screenshot "$2" < /dev/null > /dev/null 2>&1; [ "$(stat -f%z "$2" 2>/dev/null || echo 0)" -gt 250000 ] && return; echo "  blank $2, again"; sleep 3; done; }
locale_of() { case $1 in en) echo en_US;; tr) echo tr_TR;; de) echo de_DE;; es) echo es_ES;; ja) echo ja_JP;; ko) echo ko_KR;; fr) echo fr_FR;; esac; }
wanted() { [ -z "$SCENES" ] && return 0; for s in $SCENES; do [ "$s" = "$1" ] && return 0; done; return 1; }

for DEV in $DEVICES; do
  TYPE=$PHONE; [ "$DEV" = ipad ] && TYPE=$IPAD
  UDID=$(xcrun simctl create "store-$DEV" "$TYPE" "$RUNTIME")
  stamp "boot $DEV"
  xcrun simctl boot "$UDID"; limit 900 xcrun simctl bootstatus "$UDID" -b > /dev/null
  stamp "booted"
  xcrun simctl ui "$UDID" appearance light || true
  xcrun simctl status_bar "$UDID" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --operatorName '' --batteryState discharging --batteryLevel 100 || true
  xcrun simctl install "$UDID" "$APP"
  # the first launch of a fresh simulator is slow; let it settle once
  # the first launches of a fresh simulator are slow (the first frame of the town took over 20 s); warm it up twice
  for w in 25 12; do
    limit 120 xcrun simctl launch "$UDID" $BID -demoStore -demoDays 130 -demoEmpire 60 < /dev/null > /dev/null; sleep $w
    limit 30 xcrun simctl terminate "$UDID" $BID < /dev/null || true
  done
  mkdir -p "$OUT/logs"
  xcrun simctl spawn "$UDID" log stream --style compact --predicate 'process == "BalloonBaron"' > "$OUT/logs/$DEV-${LANGS// /_}.log" 2>&1 &
  LOGP=$!
  for L in $LANGS; do
    D="$OUT/$L/$DEV"; mkdir -p "$D"
    LA=(-AppleLanguages "($L)" -AppleLocale "$(locale_of "$L")")
    while IFS='|' read -r NAME DEVS WAIT ARGS; do
      NAME=$(echo "$NAME" | xargs); [ -z "$NAME" ] && continue; case $NAME in \#*) continue;; esac
      DEVS=$(echo "$DEVS" | xargs); [ "$DEVS" != "*" ] && [ "$DEVS" != "$DEV" ] && continue
      KIND=shot; case $NAME in video:*) KIND=video; NAME=${NAME#video:};; esac
      wanted "$NAME" || continue
      [ $KIND = video ] && [ "$VIDEO" = false ] && continue
      [ $KIND = shot ] && [ "$VIDEO" = only ] && continue
      # WAIT: seconds before the picture, or for a video "lead+length"
      ARGS=${ARGS//\{COMPANY\}/\"$(company_of "$L")\"}
      eval "AA=($ARGS)"
      stamp "$L $DEV $NAME"
      limit 120 xcrun simctl launch "$UDID" $BID "${LA[@]}" -demoStore "${AA[@]}" < /dev/null > /dev/null || echo "::warning::$L $DEV $NAME: launch failed"
      if [ $KIND = shot ]; then
        # several pictures of one launch: WAIT "8,3,3" takes name-0, name-1… after each pause
        IFS=',' read -ra WS <<< "$WAIT"
        if [ ${#WS[@]} = 1 ]; then sleep "$WAIT"; shoot "$UDID" "$D/$NAME.png"
        else i=0; for w in "${WS[@]}"; do sleep "$w"; shoot "$UDID" "$D/$NAME-$i.png"; i=$((i+1)); done; fi
      else
        LEAD=${WAIT%+*}; LEN=${WAIT#*+}; mkdir -p "$D/video"
        sleep "$LEAD"
        limit 300 python3 "$(dirname "$0")/record.py" "$SIMCTL" "$UDID" "$D/video/$NAME.mov" "$LEN"
        stamp "  video $(stat -f%z "$D/video/$NAME.mov" 2>/dev/null) bytes"
      fi
      if ! limit 30 xcrun simctl spawn "$UDID" launchctl list < /dev/null | grep -q $BID; then echo "::warning::$L $DEV $NAME: the app is not running (crash?)"; fi
      limit 30 xcrun simctl terminate "$UDID" $BID < /dev/null > /dev/null 2>&1 || true
    done < "$LIST"
  done
  kill $LOGP 2>/dev/null
  limit 120 xcrun simctl shutdown "$UDID"
done
find "$OUT" -type f | wc -l
