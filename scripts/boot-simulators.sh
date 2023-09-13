#!/bin/bash

devices_list_output=$(xcrun simctl list devices)

boot_simulator() {
    local simulator="$1"
    
    local uuid=""
    local status=""
    
    while IFS= read -r line; do
        if echo "$line" | grep -q "$simulator ("; then
            uuid="${line#*\(}"    
            uuid="${uuid%%)*}"    
            status="${line##*(}"    
            status="${status%%)*}"
        fi
    done <<< "$devices_list_output"

    if [ "$status" = "Shutdown" ]; then
        echo "$simulator with $uuid is shut down. Booting it up..."
        xcrun simctl boot "$uuid"
    else
        echo "$simulator with $uuid is already booted."
    fi
}

boot_simulator "iPhone 15 Pro Max"