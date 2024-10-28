#!/bin/bash

# Specify the path to your battery icon
ICON_PATH="/usr/share/icons/kora/apps/scalable/battery.svg"  # Change this path as necessary

while true; do
    # Get current battery percentage and status
    BATTERY_PERCENTAGE=$(cat /sys/class/power_supply/BAT0/capacity)
    STATUS=$(cat /sys/class/power_supply/BAT0/status)

    # Function to send a notification with an icon
    send_notification() {
        local title="$1"
        local message="$2"
        dunstify -t 5000 -u normal -i "$icon_path" "$title" "$message"
    }

    # Check battery status and send notification if at 98% and not charging
    if [[ "$BATTERY_PERCENTAGE" -eq 98 && "$STATUS" != "Charging" ]]; then
        send_notification "Battery Status" "Battery is at 98% Full. Please unplug the charger." "$ICON_PATH"
    fi

    # Sleep for a specified interval (e.g., 60 seconds)
    sleep 20
done

