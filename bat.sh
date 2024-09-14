#!/bin/bash
THRESHOLD=98

stop_charging() {

    BATTERY_LEVEL=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep percentage | awk '{print $2}' | sed s/%//)

    STATUS=$(acpi -b | grep -o 'Charging\|Discharging\|Full')

    if [ "$BATTERY_LEVEL" -ge "$THRESHOLD" ] && [ "$STATUS" == "Charging" ]; then
        echo "Battery at $BATTERY_LEVEL%, stopping charging."
        notify-send --icon=/usr/share/icons/kora/apps/scalable/battery.svg "Battery Info" "Your battery is Almost full"

    else
        :
    fi
}

while true; do
    stop_charging
    sleep 20  # Check every 20 Secs
done

