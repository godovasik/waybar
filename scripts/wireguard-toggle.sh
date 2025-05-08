#!/bin/bash

WAYBAR_ID="custom-wireguard"

# Устанавливаем иконку загрузки
echo '{"text": "󰑓", "class": "loading", "tooltip": "WireGuard: Applying changes..."}' >/tmp/wireguard-status

# Функция для обработки status.sh
function handle_status {
    # Создаем именованный канал, если его не существует
    if [ ! -p /tmp/wireguard-status ]; then
        mkfifo /tmp/wireguard-status
    fi

    # Читаем данные из канала и передаем их обратно
    while read -r line; do
        echo "$line"
    done </tmp/wireguard-status
}

# Экспортируем функцию для использования в соседнем процессе
export -f handle_status

# Запускаем обработчик в фоне
pkill -f "bash -c handle_status" || true
bash -c "handle_status" &

# Проверяем текущий статус
if [[ $(ip a show wg0 2>/dev/null) ]]; then
    sudo wg-quick down wg0
else
    sudo wg-quick up wg0
fi

# Небольшая задержка для имитации работы и обновления статуса
sleep 1

# Обновляем статус
~/.config/waybar/scripts/wireguard-status.sh >/tmp/wireguard-status

# Закрываем канал через 2 секунды
(sleep 2 && rm -f /tmp/wireguard-status) &
