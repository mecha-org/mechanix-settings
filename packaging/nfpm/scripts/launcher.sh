#!/bin/sh
APPDIR="/usr/share/mechanix/mechanix-settings"
exec "$APPDIR/mechanix_settings" --bundle="$APPDIR" "$@"
