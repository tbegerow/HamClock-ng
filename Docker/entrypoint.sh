#!/usr/bin/env sh
set -e

echo "→ HamClock-NG container starting"

# Export ENV for Perl
export CALLSIGN CALLSIGN_BACKGROUND_COLOR CALLSIGN_BACKGROUND_RAINBOW CALLSIGN_COLOR
export LOCATOR LAT LONG UTC_OFFSET VOACAP_MODE VOACAP_POWER
export FLRIG_HOST FLRIG_PORT USE_FLRIG USE_METRIC

# SERVER MODE
if [ "$HAMCLOCK_BACKEND_ENABLED" = "true" ]; then
    perl hceeprom.pl NV_BACKEND_ENABLED 1
else 
    perl hceeprom.pl NV_BACKEND_ENABLED 0
fi

# CLIENT MODE
if [ "$HAMCLOCK_USE_REMOTE_BACKEND" = "true" ]; then
    perl hceeprom.pl NV_USE_REMOTE_BACKEND 1

    perl hceeprom.pl NV_DATA_HOST "$HAMCLOCK_DATA_HOST"
    perl hceeprom.pl NV_DATA_PORT "$HAMCLOCK_DATA_PORT"
    perl hceeprom.pl NV_DATA_BASEPATH "$HAMCLOCK_DATA_BASEPATH"
else
    perl hceeprom.pl NV_USE_REMOTE_BACKEND 0
    perl hceeprom.pl NV_DATA_HOST ""
    perl hceeprom.pl NV_DATA_PORT 0
    perl hceeprom.pl NV_DATA_BASEPATH ""
fi

# TLE-Mode
HAMCLOCK_TLE_MODE="${HAMCLOCK_TLE_MODE:-backend}"

TOOLS="/hamclock/ESPHamClock/tools"

if [ "$HAMCLOCK_TLE_MODE" = "local" ]; then
  echo "→ Generating TLEs locally"

# Initial build (sonst ist user-esats leer beim ersten Start)
  echo "→ Initial TLE generation"
  "$TOOLS/build-user-esats.sh"

  # Install cron job
  echo "→ Installing TLE cronjob (every 6 hours)"
  mkdir -p /etc/crontabs
  cat <<EOF >/etc/crontabs/root
0 */6 * * * $TOOLS/build-user-esats.sh >/var/log/tle.log 2>&1
EOF

  # Start cron
  echo "→ Starting cron daemon"
  crond
else
  echo "→ TLE mode: backend (no local TLE generation)"
fi

CONFIG_DIR=/root/.hamclock/configurations
mkdir -p "$CONFIG_DIR"

# starts Hamclock for 20 sec. if .eeprom don't exist
if [ -z "$(ls -A $CONFIG_DIR/*.eeprom 2>/dev/null)" ]; then
  echo "→ Creating initial eeprom config..."
  /usr/local/bin/hamclock -t 20 &
  sleep 15
  kill -INT $!
fi

OFFSET=$((UTC_OFFSET*3600))

perl /hamclock/ESPHamClock/hceeprom.pl NV_CALLSIGN $CALLSIGN && \
perl /hamclock/ESPHamClock/hceeprom.pl NV_DE_GRID $LOCATOR && \
perl /hamclock/ESPHamClock/hceeprom.pl NV_DE_LAT $LAT && \
perl /hamclock/ESPHamClock/hceeprom.pl NV_DE_LNG $LONG && \
perl /hamclock/ESPHamClock/hceeprom.pl NV_DE_TZ $OFFSET && \
perl /hamclock/ESPHamClock/hceeprom.pl NV_BCMODE $VOACAP_MODE && \
perl /hamclock/ESPHamClock/hceeprom.pl NV_BCPOWER $VOACAP_POWER && \
perl /hamclock/ESPHamClock/hceeprom.pl NV_CALL_FG $CALLSIGN_COLOR && \
perl /hamclock/ESPHamClock/hceeprom.pl NV_CALL_BG $CALLSIGN_BACKGROUND_COLOR && \
perl /hamclock/ESPHamClock/hceeprom.pl NV_CALL_RAINBOW $CALLSIGN_BACKGROUND_RAINBOW && \
perl /hamclock/ESPHamClock/hceeprom.pl NV_FLRIGHOST $FLRIG_HOST && \
perl /hamclock/ESPHamClock/hceeprom.pl NV_FLRIGPORT $FLRIG_PORT && \
perl /hamclock/ESPHamClock/hceeprom.pl NV_FLRIGUSE $USE_FLRIG && \
#perl /hamclock/ESPHamClock/hceeprom.pl NV_METRIC_ON $USE_METRIC && \
perl /hamclock/ESPHamClock/hceeprom.pl NV_AUTOUPGRADE $AUTOUPGRADE && \
perl /hamclock/ESPHamClock/hceeprom.pl NV_WEBFS $WEB_FULLSCREEN && \
perl /hamclock/ESPHamClock/hceeprom.pl NV_SHOWPIP $SHOW_PUBLIC_IP && \

# Start HamClock
#echo "→ Starting HamClock"
#exec /usr/local/bin/hamclock -o
HAMCLOCK_ARGS="-o"

# Remote backend enabled?
if [ "${HAMCLOCK_USE_REMOTE_BACKEND:-false}" = "true" ]; then

    # Build backend string from ENV
    if [ -n "${HAMCLOCK_DATA_HOST:-}" ]; then

        BACKEND="${HAMCLOCK_DATA_HOST}"

        # append port if set
        if [ -n "${HAMCLOCK_DATA_PORT:-}" ]; then
            BACKEND="${BACKEND}:${HAMCLOCK_DATA_PORT}"
        fi

        echo "→ Using backend: $BACKEND"

        HAMCLOCK_ARGS="$HAMCLOCK_ARGS -b $BACKEND"

    else
        echo "→ Remote backend enabled but no host configured"
    fi
fi

echo "→ Starting HamClock: /usr/local/bin/hamclock $HAMCLOCK_ARGS"

exec /usr/local/bin/hamclock $HAMCLOCK_ARGS
