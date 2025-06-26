#!/bin/bash

# Скрипт для настройки интеграции Consul + Vault + Nomad
# Запускать ПОСЛЕ terraform apply

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️  $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] ℹ️  $1${NC}"
}

echo -e "${BLUE}🏠 HomeLab Integration Setup${NC}"
echo "================================"

# Проверка что сервисы запущены
check_services() {
    log "Проверка статуса сервисов..."
    
    if ! systemctl is-active --quiet consul; then
        error "Consul не запущен! Запустите: sudo systemctl start consul"
        exit 1
    fi
    
    if ! systemctl is-active --quiet vault; then
        error "Vault не запущен! Запустите: sudo systemctl start vault"
        exit 1
    fi
    
    if ! systemctl is-active --quiet nomad; then
        error "Nomad не запущен! Запустите: sudo systemctl start nomad"
        exit 1
    fi
    
    log "✅ Все сервисы запущены"
}

# Ожидание готовности сервисов
wait_for_services() {
    log "Ожидание готовности сервисов..."
    
    # Ожидание Consul
    for i in {1..30}; do
        if consul members &>/dev/null; then
            log "✅ Consul готов"
            break
        fi
        sleep 2
    done
    
    # Ожидание Vault
    for i in {1..30}; do
        if vault status &>/dev/null; then
            log "✅ Vault отвечает"
            break
        fi
        sleep 2
    done
    
    # Ожидание Nomad
    for i in {1..30}; do
        if nomad status &>/dev/null; then
            log "✅ Nomad готов"
            break
        fi
        sleep 2
    done
}

# Инициализация Vault (если еще не инициализирован)
init_vault() {
    log "Проверка инициализации Vault..."
    
    if vault status | grep -q "Initialized.*false"; then
        log "🔐 Инициализация Vault..."
        
        # Инициализация с 1 ключом (для домашней лаборатории)
        VAULT_INIT_OUTPUT=$(vault operator init -key-shares=1 -key-threshold=1 -format=json)
        
        # Сохранение ключей
        echo "$VAULT_INIT_OUTPUT" | jq -r '.unseal_keys_b64[0]' > ~/.vault-unseal-key
        echo "$VAULT_INIT_OUTPUT" | jq -r '.root_token' > ~/.vault-root-token
        
        warn "🔑 Unseal ключ сохранен в ~/.vault-unseal-key"
        warn "🎫 Root token сохранен в ~/.vault-root-token"
        
        # Unsealing
        vault operator unseal $(cat ~/.vault-unseal-key)
        
        log "✅ Vault инициализирован и разблокирован"
    else
        log "✅ Vault уже инициализирован"
        
        # Проверяем, нужно ли разблокировать
        if vault status | grep -q "Sealed.*true"; then
            if [ -f ~/.vault-unseal-key ]; then
                log "🔓 Разблокировка Vault..."
                vault operator unseal $(cat ~/.vault-unseal-key)
            else
                error "Vault заблокирован, но unseal ключ не найден!"
                exit 1
            fi
        fi
    fi
}

# Аутентификация в Vault
auth_vault() {
    log "Аутентификация в Vault..."
    
    if [ -f ~/.vault-root-token ]; then
        export VAULT_TOKEN=$(cat ~/.vault-root-token)
        log "✅ Использован сохраненный root token"
    else
        error "Root token не найден! Vault инициализирован?"
        exit 1
    fi
}

# Создание директорий для данных
create_directories() {
    log "Создание директорий для данных..."
    
    sudo mkdir -p /opt/{jellyfin,homepage,atuin}/{config,data,cache}
    sudo mkdir -p /opt/data/{postgres,redis,minio}
    
    # Права доступа
    sudo chown -R $USER:$USER /opt/
    sudo chmod -R 755 /opt/
    
    log "✅ Директории созданы"
}

# Настройка Vault policies
setup_vault_policies() {
    log "Создание Vault политик..."
    
    # Создаем директорию если не существует
    mkdir -p policies/vault
    
    # Базовая политика для Nomad
    cat > policies/vault/nomad-cluster.hcl << 'EOF'
# Политика для Nomad кластера
path "auth/token/create/nomad-cluster" {
  capabilities = ["update"]
}

path "auth/token/revoke-accessor" {
  capabilities = ["update"]
}

path "auth/token/roles/nomad-cluster" {
  capabilities = ["read"]
}

path "kv/*" {
  capabilities = ["read"]
}

path "sys/capabilities-self" {
  capabilities = ["update"]
}
EOF

    # Политика для Jellyfin
    cat > policies/vault/jellyfin.hcl << 'EOF'
# Политика для Jellyfin сервиса
path "kv/data/homelab/domains" {
  capabilities = ["read"]
}

path "kv/data/jellyfin/*" {
  capabilities = ["read"]
}

path "kv/data/common/*" {
  capabilities = ["read"]
}
EOF

    # Политика для Homepage
    cat > policies/vault/homepage.hcl << 'EOF'
# Политика для Homepage сервиса
path "kv/data/homelab/domains" {
  capabilities = ["read"]
}

path "kv/data/homepage/*" {
  capabilities = ["read"]
}

path "kv/data/common/*" {
  capabilities = ["read"]
}
EOF

    # Применение политик
    vault policy write nomad-cluster policies/vault/nomad-cluster.hcl
    vault policy write jellyfin policies/vault/jellyfin.hcl
    vault policy write homepage policies/vault/homepage.hcl
    
    log "✅ Vault политики созданы"
}

# Настройка Nomad интеграции с Vault
setup_nomad_vault_integration() {
    log "Настройка интеграции Nomad с Vault..."
    
    # Создание роли для Nomad
    vault write auth/token/roles/nomad-cluster \
        allowed_policies="nomad-cluster" \
        explicit_max_ttl=0 \
        name="nomad-cluster" \
        orphan=true \
        period=259200 \
        renewable=true
    
    # Создание токена для Nomad
    NOMAD_VAULT_TOKEN=$(vault write -field=token auth/token/create/nomad-cluster)
    
    # Сохранение токена для Nomad
    echo "$NOMAD_VAULT_TOKEN" | sudo tee /etc/nomad.d/vault-token >/dev/null
    sudo chmod 600 /etc/nomad.d/vault-token
    
    # Обновление конфигурации Nomad
    if ! grep -q "token" /etc/nomad.d/config.hcl; then
        sudo bash -c 'cat >> /etc/nomad.d/config.hcl << EOF

vault {
  enabled = true
  address = "http://127.0.0.1:8200"
  token   = "'"$NOMAD_VAULT_TOKEN"'"
}
EOF'
    fi
    
    log "✅ Nomad интегрирован с Vault"
}

# Включение KV движка в Vault
enable_kv_engine() {
    log "Включение KV движка в Vault..."
    
    if ! vault secrets list | grep -q "kv/"; then
        vault secrets enable -path=kv kv-v2
        log "✅ KV движок включен"
    else
        log "✅ KV движок уже включен"
    fi
}

# Создание базовых секретов
create_base_secrets() {
    log "Создание базовых секретов..."
    
    # Домены
    vault kv put kv/homelab/domains \
        jellyfin="jellyfin.cosmdandy.ru" \
        homepage="homepage.cosmdandy.ru" \
        base="cosmdandy.ru"
    
    # Информация о владельце
    vault kv put kv/homelab/owner \
        name="CosmDandy" \
        email="admin@cosmdandy.ru" \
        contact="telegram:@cosmdandy"
    
    # Jellyfin секреты
    vault kv put kv/jellyfin/config \
        api_key="$(openssl rand -hex 32)" \
        admin_password="$(openssl rand -base64 16)"
    
    # Homepage секреты
    vault kv put kv/homepage/config \
        allowed_hosts="homepage.cosmdandy.ru"
    
    log "✅ Базовые секреты созданы"
}

# Настройка Consul KV
setup_consul_kv() {
    log "Настройка Consul KV..."
    
    # Базовые настройки
    consul kv put homelab/datacenter "homelab"
    consul kv put homelab/environment "production"
    
    # Jellyfin настройки
    consul kv put jellyfin/ports/http "8096"
    consul kv put jellyfin/resources/cpu "4000"
    consul kv put jellyfin/resources/memory "2048"
    consul kv put jellyfin/features/dlna "true"
    consul kv put jellyfin/logging/level "Information"
    
    # Homepage настройки
    consul kv put homepage/port "3000"
    consul kv put homepage/resources/cpu "500"
    consul kv put homepage/resources/memory "512"
    
    log "✅ Consul KV настроен"
}

# Перезапуск сервисов для применения новых настроек
restart_services() {
    log "Перезапуск сервисов..."
    
    sudo systemctl restart nomad
    
    # Ожидание готовности Nomad
    sleep 10
    
    if nomad status &>/dev/null; then
        log "✅ Nomad перезапущен и готов"
    else
        error "Проблема с перезапуском Nomad"
        exit 1
    fi
}

# Проверка интеграции
verify_integration() {
    log "Проверка интеграции..."
    
    # Проверка Nomad + Vault
    if nomad status | grep -q "ready"; then
        log "✅ Nomad готов"
    else
        warn "⚠️  Nomad может иметь проблемы"
    fi
    
    # Проверка доступа к секретам
    if vault kv get kv/homelab/domains &>/dev/null; then
        log "✅ Доступ к секретам работает"
    else
        error "❌ Проблемы с доступом к секретам"
    fi
    
    # Проверка Consul KV
    if consul kv get homelab/datacenter &>/dev/null; then
        log "✅ Consul KV работает"
    else
        error "❌ Проблемы с Consul KV"
    fi
}

# Основная функция
main() {
    log "🚀 Начинаем настройку интеграции HomeLab"
    
    # check_services
    # wait_for_services
    init_vault
    auth_vault
    create_directories
    enable_kv_engine
    setup_vault_policies
    setup_nomad_vault_integration
    create_base_secrets
    setup_consul_kv
    restart_services
    verify_integration
    
    echo
    log "🎉 Интеграция настроена успешно!"
    echo
    info "📋 Что дальше:"
    echo "  1. Vault UI: http://localhost:8200"
    echo "  2. Consul UI: http://localhost:8500"
    echo "  3. Nomad UI: http://localhost:4646"
    echo "  4. Запуск сервисов: nomad run nomad/jellyfin.nomad.hcl"
    echo
    warn "🔑 Важно: Сохраните файлы ~/.vault-unseal-key и ~/.vault-root-token!"
}

# Запуск
main "$@"
