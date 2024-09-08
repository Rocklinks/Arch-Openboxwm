#!/bin/bash
# Define the battery device
BATTERY_DEVICE=$(upower -e | grep battery)

# Check if the battery device was found
if [ -z "$BATTERY_DEVICE" ]; then
    echo "No battery device found."
    exit 1
fi

# Loop indefinitely
while true; do
    # Get the battery percentage
    charge=$(upower -i "$BATTERY_DEVICE" | grep percentage | awk '{print $2}' | tr -d '%')

    # Check if the charge variable is a number
    if ! [[ "$charge" =~ ^[0-9]+$ ]]; then
        echo "Failed to retrieve battery percentage."
        sleep 10
        continue
    fi

    # Check if the charge is 99%
    if [ "$charge" -eq 99 ]; then
        notify-send --icon=/usr/share/icons/kora/devices/scalable/gnome-dev-battery.svg "Battery Status" "Your battery is almost fully charged"
        
        # Delay for 60 seconds to avoid spamming notifications
        sleep 60
    fi

    # Delay for 10 seconds before checking again
    sleep 2
done

