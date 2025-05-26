#!/bin/bash

COMPONENT=$1   # Имя компонента (consul, vault, nomad)
CONFIG_FILE=$2 # Путь к конфигурационному файлу

echo "Установка $COMPONENT..."
sudo apt-get update
sudo apt-get install -y $COMPONENT

# Определение директории и имени файла конфигурации
if [ "$COMPONENT" = "consul" ]; then
  CONFIG_DIR="/etc/$COMPONENT.d"
  CONFIG_DEST="$CONFIG_DIR/config.json"
else
  CONFIG_DIR="/etc/$COMPONENT.d"
  CONFIG_DEST="$CONFIG_DIR/config.hcl"
fi

# Создание директории для конфигурации
sudo mkdir -p $CONFIG_DIR

# Копирование конфигурационного файла
sudo cp $CONFIG_FILE $CONFIG_DEST

# Настройка systemd-сервиса
sudo systemctl enable $COMPONENT
sudo systemctl start $COMPONENT

echo "$COMPONENT установлен и запущен"
