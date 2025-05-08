#!/bin/bash

# Определить основной интерфейс
IFACE=$(ip route get 1.1.1.1 2>/dev/null | grep -Po '(?<=dev\s)\w+' || echo "lo")

# Начальные значения
R1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
T1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
sleep 1
R2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
T2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)

# Рассчитываем скорость в KB/s
TBPS=$(expr $T2 - $T1)
RBPS=$(expr $R2 - $R1)
TKBPS=$(expr $TBPS / 1024)
RKBPS=$(expr $RBPS / 1024)

# Форматируем вывод
if [ $RKBPS -gt 1024 ]; then
    RKBPS=$(echo "scale=1; $RKBPS / 1024" | bc)
    RUNIT="MB/s"
else
    RUNIT="KB/s"
fi

if [ $TKBPS -gt 1024 ]; then
    TKBPS=$(echo "scale=1; $TKBPS / 1024" | bc)
    TUNIT="MB/s"
else
    TUNIT="KB/s"
fi

echo "{\"text\": \"⇣${RKBPS}${RUNIT} ⇡${TKBPS}${TUNIT}\"}"
