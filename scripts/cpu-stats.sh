#!/bin/bash

# Получаем загрузку CPU
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | awk '{printf "%.1f", $0}')

# Получаем температуру CPU
CPU_TEMP_PATH="/sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon1/temp1_input"
if [ -f "$CPU_TEMP_PATH" ]; then
    CPU_TEMP=$(awk '{printf "%.1f", $1 / 1000}' $CPU_TEMP_PATH)
else
    CPU_TEMP="N/A"
fi

# Получаем частоту CPU
CPU_FREQ=$(grep 'cpu MHz' /proc/cpuinfo | awk '{sum += $4; count++} END {printf "%.2f", sum/count/1000}')

# Получаем загрузку по ядрам
CORES_INFO=""
CORE_COUNT=0
while IFS= read -r line; do
    if [[ $line =~ ^cpu[0-9]+ ]]; then
        CORE_NUM=$(echo "$line" | cut -d' ' -f1 | sed 's/cpu//')
        USER=$(echo "$line" | awk '{print $2}')
        NICE=$(echo "$line" | awk '{print $3}')
        SYS=$(echo "$line" | awk '{print $4}')
        IDLE=$(echo "$line" | awk '{print $5}')

        TOTAL=$((USER + NICE + SYS + IDLE))
        USAGE=$((USER + NICE + SYS))
        PERCENT=$(awk -v usage=$USAGE -v total=$TOTAL 'BEGIN {printf "%.1f", (usage / total) * 100}')

        # Важно: используем экранированные \\n вместо реальных переносов строк
        CORES_INFO="${CORES_INFO}Core ${CORE_NUM}: ${PERCENT}%\\n"
        CORE_COUNT=$((CORE_COUNT + 1))
    fi
done </proc/stat

# Получаем количество процессов
PROCESS_COUNT=$(ps aux | wc -l)
PROCESS_COUNT=$((PROCESS_COUNT - 1)) # Вычитаем заголовок

# Получаем load average
LOAD_AVG=$(cat /proc/loadavg | awk '{printf "%s %s %s", $1, $2, $3}')

# Основной текст и tooltip для waybar - используем экранированные переносы строк
TEXT="${CPU_USAGE}%, ${CPU_TEMP}°C"
TOOLTIP="CPU Usage: ${CPU_USAGE}%\\nCPU Temperature: ${CPU_TEMP}°C\\nCPU Frequency: ${CPU_FREQ} GHz\\nActive Processes: ${PROCESS_COUNT}\\nLoad Average: ${LOAD_AVG}\\n\\nCore Usage:\\n${CORES_INFO}"

# Определяем класс в зависимости от загрузки
CLASS="normal"
if (($(echo "$CPU_USAGE > 70" | bc -l))); then
    CLASS="warning"
fi
if (($(echo "$CPU_USAGE > 90" | bc -l))); then
    CLASS="critical"
fi

# Важно! Используем одну строку вывода без переносов, с правильно экранированными \n
echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"$CLASS\"}"
