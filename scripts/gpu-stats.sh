bin/bash

# Явно указываем пути для вашей AMD GPU
GPU_CARD_PATH="/sys/class/drm/card1"
HWMON_PATH="/sys/class/drm/card1/device/hwmon/hwmon2"
BUSY_PERCENT_PATH="/sys/class/drm/card1/device/gpu_busy_percent"
TEMP_PATH="$HWMON_PATH/temp1_input"
POWER_PATH="$HWMON_PATH/power1_average"

# Проверяем наличие основных файлов
if [ -d "$GPU_CARD_PATH" ] && grep -q amdgpu "$GPU_CARD_PATH/device/driver/module/drivers" 2>/dev/null; then
    # Получаем загрузку GPU
    if [ -f "$BUSY_PERCENT_PATH" ]; then
        GPU_USAGE=$(cat "$BUSY_PERCENT_PATH")
    else
        GPU_USAGE="N/A"
    fi

    # Получаем температуру GPU
    if [ -f "$TEMP_PATH" ]; then
        GPU_TEMP=$(awk '{printf "%.1f", $1 / 1000}' "$TEMP_PATH")
    else
        # Попробуем найти температуру в других местах
        TEMP_PATH=$(find "$GPU_CARD_PATH/device/" -name "temp1_input" 2>/dev/null | head -n 1)
        if [ -f "$TEMP_PATH" ]; then
            GPU_TEMP=$(awk '{printf "%.1f", $1 / 1000}' "$TEMP_PATH")
        else
            GPU_TEMP="N/A"
        fi
    fi

    # Получаем частоту GPU
    GPU_FREQ="N/A"
    # Проверяем возможные пути для частоты
    FREQ_FILES=(
        "$HWMON_PATH/freq1_input"
        "$GPU_CARD_PATH/device/pp_dpm_sclk"
    )

    for FILE in "${FREQ_FILES[@]}"; do
        if [ -f "$FILE" ]; then
            if [[ "$FILE" == *"freq1_input"* ]]; then
                GPU_FREQ=$(awk '{printf "%.0f", $1 / 1000000}' "$FILE")
                break
            elif [[ "$FILE" == *"pp_dpm_sclk"* ]]; then
                GPU_FREQ=$(grep '*' "$FILE" | awk '{print $2}' | sed 's/Mhz//')
                break
            fi
        fi
    done

    # Получаем частоту памяти GPU
    MEM_FREQ="N/A"
    MEM_FREQ_FILES=(
        "$HWMON_PATH/freq2_input"
        "$GPU_CARD_PATH/device/pp_dpm_mclk"
    )

    for FILE in "${MEM_FREQ_FILES[@]}"; do
        if [ -f "$FILE" ]; then
            if [[ "$FILE" == *"freq2_input"* ]]; then
                MEM_FREQ=$(awk '{printf "%.0f", $1 / 1000000}' "$FILE")
                break
            elif [[ "$FILE" == *"pp_dpm_mclk"* ]]; then
                MEM_FREQ=$(grep '*' "$FILE" | awk '{print $2}' | sed 's/Mhz//')
                break
            fi
        fi
    done

    # Получаем использование VRAM
    VRAM_USAGE="N/A"
    # Проверяем наличие radeontop
    if command -v radeontop &>/dev/null; then
        VRAM_INFO=$(timeout 1s radeontop -d- -l1 2>/dev/null)
        if [ $? -eq 0 ]; then
            VRAM_USAGE=$(echo "$VRAM_INFO" | grep -o 'vram.*%' | awk '{printf "%.1f", $2}')
        fi
    fi

    # Получаем энергопотребление
    POWER="N/A"
    if [ -f "$POWER_PATH" ]; then
        POWER=$(awk '{printf "%.1f", $1 / 1000000}' "$POWER_PATH")
    fi

    # Определяем класс в зависимости от загрузки
    CLASS="normal"
    if [ "$GPU_USAGE" != "N/A" ] && (($(echo "$GPU_USAGE > 70" | bc -l))); then
        CLASS="warning"
    fi
    if [ "$GPU_USAGE" != "N/A" ] && (($(echo "$GPU_USAGE > 90" | bc -l))); then
        CLASS="critical"
    fi

    # Формируем текст и подсказку
    TEXT="${GPU_USAGE}%, ${GPU_TEMP}°C"
    TOOLTIP="GPU Usage: ${GPU_USAGE}%\nGPU Temperature: ${GPU_TEMP}°C\nGPU Frequency: ${GPU_FREQ} MHz\nMemory Frequency: ${MEM_FREQ} MHz\nVRAM Usage: ${VRAM_USAGE}%\nPower Consumption: ${POWER} W"

elif command -v nvidia-smi &>/dev/null; then
    # Для NVIDIA GPU
    GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
    GPU_USAGE=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
    GPU_FREQ=$(nvidia-smi --query-gpu=clocks.gr --format=csv,noheader,nounits)
    MEM_FREQ=$(nvidia-smi --query-gpu=clocks.mem --format=csv,noheader,nounits)
    MEMORY_USED=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
    MEMORY_TOTAL=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)
    MEMORY_PERCENT=$(awk -v used=$MEMORY_USED -v total=$MEMORY_TOTAL 'BEGIN {printf "%.1f", (used / total) * 100}')
    POWER=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits)

    # Определяем класс в зависимости от загрузки
    CLASS="normal"
    if (($(echo "$GPU_USAGE > 70" | bc -l))); then
        CLASS="warning"
    fi
    if (($(echo "$GPU_USAGE > 90" | bc -l))); then
        CLASS="critical"
    fi

    # Формируем текст и подсказку
    TEXT="${GPU_USAGE}%, ${GPU_TEMP}°C"
    TOOLTIP="GPU Usage: ${GPU_USAGE}%\nGPU Temperature: ${GPU_TEMP}°C\nGPU Frequency: ${GPU_FREQ} MHz\nMemory Frequency: ${MEM_FREQ} MHz\nVRAM Usage: ${MEMORY_PERCENT}% (${MEMORY_USED} MB / ${MEMORY_TOTAL} MB)\nPower Consumption: ${POWER} W"
else
    # Fallback для систем без определяемого GPU
    TEXT="GPU: N/A"
    TOOLTIP="No dedicated GPU detected"
    CLASS="normal"
fi

# Возвращаем результат в формате JSON для waybar
echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"$CLASS\"}"
