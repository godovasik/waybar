#!/bin/bash

# Проверяем наличие nvidia-smi
if command -v nvidia-smi &>/dev/null; then
    # Для NVIDIA
    TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
    MEMORY=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits | awk -F ', ' '{printf "%.1f", $1 / $2 * 100}')
    TEXT="${TEMP}°C, ${MEMORY}%"
    TOOLTIP="GPU Temperature: ${TEMP}°C\nGPU Memory Usage: ${MEMORY}%"
elif grep -q amdgpu /sys/class/drm/*/device/driver/module/drivers &>/dev/null; then
    # Для AMD GPU через sysfs
    # Получаем путь к первому amdgpu
    AMD_PATH=$(find /sys/class/drm -name "card*" -exec sh -c "[ -d {}/device/driver/module/drivers/pci:amdgpu ] && echo {}" \; | head -n 1)

    if [ -n "$AMD_PATH" ]; then
        if [ -f "$AMD_PATH/device/hwmon/hwmon*/temp1_input" ]; then
            TEMP_FILE=$(find $AMD_PATH/device/hwmon/hwmon* -name "temp1_input" | head -n 1)
            TEMP=$(awk '{printf "%.1f", $1 / 1000}' $TEMP_FILE)

            # Для памяти amdgpu необходимо использовать другой метод
            # Здесь используем приблизительное значение
            MEMORY_INFO=$(grep -m 1 -A 3 "^GPU Memory:" /var/log/Xorg.0.log 2>/dev/null | grep "Total" | grep -o "[0-9]\+")
            if [ -n "$MEMORY_INFO" ]; then
                MEMORY=$(echo "scale=1; $(free -m | grep Mem | awk '{print $3}') / $MEMORY_INFO * 100" | bc)
            else
                MEMORY="N/A"
            fi

            TEXT="${TEMP}°C, ${MEMORY}%"
            TOOLTIP="GPU Temperature: ${TEMP}°C\nGPU Memory Usage: ${MEMORY}%"
        else
            TEXT="GPU: N/A"
            TOOLTIP="Could not read AMD GPU information"
        fi
    else
        TEXT="GPU: N/A"
        TOOLTIP="AMD GPU not found"
    fi
else
    # Fallback для систем без определяемого GPU
    TEXT="GPU: N/A"
    TOOLTIP="No dedicated GPU detected"
fi

echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\"}"
