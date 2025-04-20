#!/usr/bin/env bash

WATCH_DIR="/php/php-${PHP_VERSION}/lib/php/extensions"

START_CMD="php -S 0.0.0.0:80 -t /php/server/public"
KILL_CMD="pkill -HUP php"

if ! pgrep -f "php -S localhost:80" > /dev/null; then
    $START_CMD &
fi

inotifywait -m -r -e modify,create,delete "$WATCH_DIR" | while read -r path event file; do
    $KILL_CMD
    $START_CMD &
done