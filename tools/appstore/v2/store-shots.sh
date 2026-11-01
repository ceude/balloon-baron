#!/bin/bash
# Captures the App Store raw screens from the real app on simulators (run by .github/workflows/store-shots.yml).
# Usage: store-shots.sh <BalloonBaron.app> <out dir>   env: LANGS, DEVICES, SCENES (empty = all), VIDEO (true/false)
# Scenes come from store-shots.txt next to this script.
set -u
APP=$1; OUT=$2
LIST="$(dirname "$0")/store-shots.txt"
LANGS=${LANGS:-"en tr de es ja ko"}; DEVICES=${DEVICES:-"iphone ipad"}; SCENES=${SCENES:-}; VIDEO=${VIDEO:-false}
BID=com.ceude.balloonbaron
mkdir -p "$OUT"

RUNTIME=$(xcrun simctl list runtimes available | grep -o 'com.apple.CoreSimulator.SimRuntime.iOS-[0-9-]*' | sort -V | tail -n 1)
pick() { for t in "$@"; do xcrun simctl list devicetypes | grep -q "SimDeviceType.$t)" && { echo "com.apple.CoreSimulator.SimDeviceType.$t"; return; }; done; }
PHONE=$(pick iPhone-17-Pro-Max iPhone-16-Pro-Max)
IPAD=$(pick iPad-Pro-13-inch-M5-12GB iPad-Pro-13-inch-M5 iPad-Pro-13-inch-M4-8GB iPad-Pro-13-inch-M4-16GB)
echo "runtime $RUNTIME / phone $PHONE / ipad $IPAD"
locale_of() { case $1 in en) echo en_US;; tr) echo tr_TR;; de) echo de_DE;; es) echo es_ES;; ja) echo ja_JP;; ko) echo ko_KR;; esac; }
wanted() { [ -z "$SCENES" ] && return 0; for s in $SCENES; do [ "$s" = "$1" ] && return 0; done; return 1; }

for DEV in $DEVICES; do
  TYPE=$PHONE; [ "$DEV" = ipad ] && TYPE=$IPAD
  UDID=$(xcrun simctl create "store-$DEV" "$TYPE" "$RUNTIME")
  xcrun simctl boot "$UDID"; xcrun simctl bootstatus "$UDID" -b > /dev/null
  xcrun simctl ui "$UDID" appearance light || true
  xcrun simctl status_bar "$UDID" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --operatorName '' --batteryState charged --batteryLevel 100 || true
  xcrun simctl install "$UDID" "$APP"
  # the first launch of a fresh simulator is slow; let it settle once
  xcrun simctl launch "$UDID" $BID -demoDays 1 < /dev/null > /dev/null; sleep 12; xcrun simctl terminate "$UDID" $BID < /dev/null || true
  for L in $LANGS; do
    D="$OUT/$L/$DEV"; mkdir -p "$D"
    LA=(-AppleLanguages "($L)" -AppleLocale "$(locale_of "$L")")
    while IFS='|' read -r NAME DEVS WAIT ARGS; do
      NAME=$(echo "$NAME" | xargs); [ -z "$NAME" ] && continue; case $NAME in \#*) continue;; esac
      DEVS=$(echo "$DEVS" | xargs); [ "$DEVS" != "*" ] && [ "$DEVS" != "$DEV" ] && continue
      KIND=shot; case $NAME in video:*) KIND=video; NAME=${NAME#video:};; esac
      wanted "$NAME" || continue
      [ $KIND = video ] && [ "$VIDEO" != true ] && continue
      # WAIT: seconds before the picture, or for a video "lead+length"
      xcrun simctl launch "$UDID" $BID "${LA[@]}" $ARGS < /dev/null > /dev/null
      if [ $KIND = shot ]; then
        # several pictures of one launch: WAIT "8,3,3" takes name-0, name-1… after each pause
        IFS=',' read -ra WS <<< "$WAIT"
        if [ ${#WS[@]} = 1 ]; then sleep "$WAIT"; xcrun simctl io "$UDID" screenshot "$D/$NAME.png" < /dev/null > /dev/null 2>&1
        else i=0; for w in "${WS[@]}"; do sleep "$w"; xcrun simctl io "$UDID" screenshot "$D/$NAME-$i.png" < /dev/null > /dev/null 2>&1; i=$((i+1)); done; fi
      else
        LEAD=${WAIT%+*}; LEN=${WAIT#*+}; mkdir -p "$D/video"
        sleep "$LEAD"
        xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$D/video/$NAME.mov" < /dev/null > /dev/null 2>&1 &
        REC=$!; sleep "$LEN"; kill -INT $REC; wait $REC 2>/dev/null
      fi
      if ! xcrun simctl spawn "$UDID" launchctl list < /dev/null | grep -q $BID; then echo "::warning::$L $DEV $NAME: the app is not running (crash?)"; fi
      xcrun simctl terminate "$UDID" $BID < /dev/null > /dev/null 2>&1 || true
      echo "$L $DEV $NAME"
    done < "$LIST"
  done
  xcrun simctl shutdown "$UDID"
done
find "$OUT" -type f | wc -l
