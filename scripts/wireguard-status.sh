#!/bin/bash

if [[ $(ip a show wg0 2>/dev/null) ]]; then
    echo '{"text": "󰒄", "class": "connected", "tooltip": "WireGuard: Connected"}'
else
    echo '{"text": "󰒅", "class": "disconnected", "tooltip": "WireGuard: Disconnected"}'
fi
