#!/bin/bash
APP="/Applications/NotifiCLI.app"

if [ ! -d "$APP" ]; then
    osascript -e 'display dialog "NotifiCLI.app was not found in your Applications folder.\n\nPlease drag NotifiCLI.app to Applications first, then run this script again." buttons {"OK"} default button "OK" with icon stop with title "NotifiCLI - Fix Security"'
    exit 1
fi

xattr -cr "$APP"

osascript -e 'display dialog "NotifiCLI is now unblocked!\n\nYou can now open it normally." buttons {"OK"} default button "OK" with icon note with title "NotifiCLI - Fix Security"'
