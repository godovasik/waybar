#!/bin/bash

# Путь к файлам с данными
GPU_USAGE_FILE="/sys/class/drm/card1/device/hwmon/hwmon2/device/gpu_busy_percent"
CPU_TEMP_FILE="/sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon1/temp1_input"

# Чтение значений
if [ -f "$GPU_USAGE_FILE" ]; then
    GPU_USAGE_RAW=$(cat $GPU_USAGE_FILE)
    GPU_USAGE=$(printf "%2.0f" $GPU_USAGE_RAW)
else
    GPU_USAGE="N/A"
fi

if [ -f "$CPU_TEMP_FILE" ]; then
    CPU_TEMP_RAW=$(cat $CPU_TEMP_FILE)
    CPU_TEMP=$(echo "scale=0; $CPU_TEMP_RAW / 1000" | bc)
else
    CPU_TEMP="N/A"
fi

# Вывод для Waybar
echo "${GPU_USAGE}% | ${CPU_TEMP}°C"

# Вывод для всплывающей подсказки
echo "GPU загрузка: ${GPU_USAGE}%
CPU температура: ${CPU_TEMP}°C"
