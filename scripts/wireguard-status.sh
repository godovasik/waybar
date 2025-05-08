#!/bin/bash

if [[ $(ip a show wg0 2>/dev/null) ]]; then
    echo '{"text": "wg", "class": "connected", "tooltip": "WireGuard: Connected"}'
else
    echo '{"text": "wg", "class": "disconnected", "tooltip": "WireGuard: Disconnected"}'
fi
