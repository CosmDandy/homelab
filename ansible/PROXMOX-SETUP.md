# Автоматическая настройка Proxmox VE через Ansible

Этот playbook автоматически запускает community post-install script на всех ваших Proxmox серверах без интерактивного меню.

## Структура файлов
```
proxmox-setup/
├── proxmox-post-install.yml    # Основной playbook
├── proxmox-inventory.ini       # Список серверов
├── ansible.cfg                 # Конфигурация Ansible
└── PROXMOX-SETUP.md           # Эта инструкция
```

## Что делает скрипт

✅ **Отключает Enterprise Repository** (платный)  
✅ **Включает No-Subscription Repository** (бесплатный)  
✅ **Убирает назойливое уведомление о подписке**  
✅ **Обновляет систему до последней версии**  
✅ **Устанавливает дополнительные утилиты**  

## Подготовка

### 1. Установите Ansible
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install ansible

# CentOS/RHEL
sudo yum install ansible
```

### 2. Настройте SSH доступ
```bash
# Генерируем ключ если его нет
ssh-keygen -t rsa -b 4096

# Копируем на каждый Proxmox сервер
ssh-copy-id root@192.168.20.151
ssh-copy-id root@192.168.20.152  
ssh-copy-id root@192.168.20.153
```

### 3. Настройте inventory
Отредактируйте `proxmox-inventory.ini` и укажите IP адреса ваших серверов:
```ini
[proxmox_servers]
proxmox-01 ansible_host=YOUR_IP_1
proxmox-02 ansible_host=YOUR_IP_2
proxmox-03 ansible_host=YOUR_IP_3
```

## Запуск

### Проверка доступности серверов
```bash
ansible all -m ping
```
Должен вернуться SUCCESS для всех серверов.

### Запуск post-install script

**Полностью автоматический режим (рекомендуется):**
```bash
ansible-playbook proxmox-post-install.yml
```

**С перезагрузкой после выполнения:**
```bash
ansible-playbook proxmox-post-install.yml -e reboot_after_install=true
```

**На конкретном сервере:**
```bash
ansible-playbook proxmox-post-install.yml --limit proxmox-01
```

**В ручном режиме (без автоответов):**
```bash
ansible-playbook proxmox-post-install.yml -e auto_answer=false
```

## Параметры настройки

Вы можете изменить поведение скрипта через переменные:

```bash
# Автоматически отвечать "Y" на все вопросы (по умолчанию: true)
-e auto_answer=true

# Перезагрузить после выполнения (по умолчанию: false)  
-e reboot_after_install=true

# Таймаут выполнения скрипта в секундах (по умолчанию: 1800)
-e script_timeout=3600
```

## Проверка результата

После выполнения playbook проверьте:

### 1. Репозитории
```bash
# Проверяем что enterprise repo отключен
ansible all -m shell -a "cat /etc/apt/sources.list.d/pve-enterprise.list"

# Проверяем что no-subscription repo включен  
ansible all -m shell -a "grep -r pve-no-subscription /etc/apt/sources.list*"
```

### 2. Обновления работают
```bash
ansible all -m shell -a "apt update"
```

### 3. Версия Proxmox
```bash
ansible all -m shell -a "pveversion"
```

## Что происходит во время выполнения

1. **Проверка системы** - убеждается что это Proxmox VE
2. **Загрузка скрипта** - скачивает актуальную версию  
3. **Автоматический запуск** - выполняет с флагом "Y" на все вопросы
4. **Проверка изменений** - верифицирует что репозитории настроены
5. **Обновление пакетов** - обновляет список пакетов
6. **Опциональная перезагрузка** - если включена
7. **Очистка** - удаляет временные файлы

## Устранение проблем

### Если скрипт зависает:
- Увеличьте `script_timeout`
- Проверьте интернет-соединение на серверах

### Если ошибки доступа:
```bash
# Проверьте SSH подключение
ansible all -m shell -a "whoami"

# Проверьте права root
ansible all -m shell -a "id"
```

### Если репозитории не работают:
```bash
# Ручная проверка на сервере
ssh root@YOUR_PROXMOX_IP
cat /etc/apt/sources.list.d/pve-enterprise.list
apt update
```

## Результат

После успешного выполнения:
- ✅ Proxmox обновлен до последней версии
- ✅ Убрано назойливое уведомление о подписке  
- ✅ Настроены бесплатные репозитории
- ✅ Ситема готова к работе

**Теперь можете войти в веб-интерфейс Proxmox без предупреждений о подписке!**
