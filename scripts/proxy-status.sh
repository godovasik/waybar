#!/bin/bash

# Проверяем, слушает ли что-то 1080 порт
if [[ $(
    ss -lntu | grep -q ":1080"
    echo $?
) -eq 0 ]]; then
    echo '{"text": "proxy", "class": "connected", "tooltip": "SOCKS5 Proxy: Running"}'
else
    echo '{"text": "proxy", "class": "disconnected", "tooltip": "SOCKS5 Proxy: Stopped"}'
fi
