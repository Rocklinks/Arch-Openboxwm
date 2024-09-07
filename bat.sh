#!/bin/bash

# Define the battery device
BATTERY_DEVICE="/org/freedesktop/UPower/devices/battery_BAT0"

# Get the battery percentage
charge=$(upower -i $BATTERY_DEVICE | grep percentage | awk '{print $2}' | sed 's/%//')

# Check if the charge is 100%
if [ "$charge" -eq 99 ]; then
    notify-send --icon=/usr/share/icons/kora/devices/scalable/gnome-dev-battery.svg "Battery Status" "Your battery is Almost fully charged"
fi

