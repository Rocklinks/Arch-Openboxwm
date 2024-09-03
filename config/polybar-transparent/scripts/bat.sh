#!/bin/bash

# Function to check battery status
check_battery() {
    # Get the battery percentage
    battery_percentage=$(cat /sys/class/power_supply/BAT0/capacity)

    # Check if the battery is at 100%
    if [ "$battery_percentage" -eq 100 ]; then
        send_notification
    fi
}

# Function to send notification
send_notification() {
    notify-send "Battery Status" "Your battery is fully charged (100%)!" --icon=dialog-information
}

# Execute the battery check
check_battery

