#!/bin/bash

WAYBAR_ID="custom-proxy"

# Устанавливаем иконку загрузки
echo '{"text": "proxy", "class": "loading", "tooltip": "SOCKS5 Proxy: Applying changes..."}' >/tmp/proxy-status

# Функция для обработки status.sh
function handle_status {
    # Создаем именованный канал, если его не существует
    if [ ! -p /tmp/proxy-status ]; then
        mkfifo /tmp/proxy-status
    fi

    # Читаем данные из канала и передаем их обратно
    while read -r line; do
        echo "$line"
    done </tmp/proxy-status
}

# Экспортируем функцию для использования в соседнем процессе
export -f handle_status

# Запускаем обработчик в фоне
pkill -f "bash -c handle_status" || true
bash -c "handle_status" &

# Проверяем текущий статус и делаем действие
# Здесь вы должны заменить на ваш скрипт запуска/остановки прокси
if [[ $(
    ss -lntu | grep -q ":1080"
    echo $?
) -eq 0 ]]; then
    # Здесь команда для остановки вашего SOCKS5 прокси
    # Например: killall -9 your_proxy_program
    echo "Stopping proxy" >/dev/null
else
    # Здесь команда для запуска вашего SOCKS5 прокси
    # Например: your_proxy_program &
    echo "Starting proxy" >/dev/null
fi

# Небольшая задержка для имитации работы и обновления статуса
sleep 1

# Обновляем статус
~/.config/waybar/scripts/proxy-status.sh >/tmp/proxy-status

# Закрываем канал через 2 секунды
(sleep 2 && rm -f /tmp/proxy-status) &
