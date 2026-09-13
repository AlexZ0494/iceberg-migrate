#!/bin/bash
# start.sh — автозапуск big data кластера
# Запуск: chmod +x start.sh && ./start.sh

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

step()  { echo -e "\n${CYAN}>>> $1${NC}"; }
ok()    { echo -e "    ${GREEN}OK: $1${NC}"; }
err()   { echo -e "    ${RED}ERROR: $1${NC}"; }

# 1. Запуск Docker Compose
step "Сборка и запуск контейнеров..."
docker compose up -d --build
ok "Контейнеры запущены"

# 2. Ждём, пока NameNode поднимется
step "Ожидание NameNode (до 3 минут)..."
ready=false
for i in $(seq 1 36); do
    if docker inspect --format='{{.State.Running}}' namenode 2>/dev/null | grep -q true; then
        if docker exec namenode hdfs dfs -ls / >/dev/null 2>&1; then
            ready=true
            break
        fi
    fi
    sleep 5
done
if [ "$ready" = false ]; then
    err "NameNode не поднялся за 3 минуты. Проверь: docker compose logs namenode"
    docker compose ps
    exit 1
fi
ok "NameNode готов"

# 3. Создать Hive-директории в HDFS
step "Создание директорий в HDFS..."
docker exec namenode hdfs dfs -mkdir -p /user/hive/warehouse
docker exec namenode hdfs dfs -mkdir -p /warehouse
docker exec namenode hdfs dfs -mkdir -p /spark-events
docker exec namenode hdfs dfs -chmod -R 777 /user/hive /warehouse /spark-events
ok "HDFS-директории созданы"

# 4. Ждём Trino
step "Ожидание Trino (до 2 минут)..."
trino_ready=false
for i in $(seq 1 24); do
    if docker exec trino trino --execute "SHOW CATALOGS" >/dev/null 2>&1; then
        trino_ready=true
        break
    fi
    sleep 5
done

# 5. Проверка Trino
step "Проверка Trino..."
if [ "$trino_ready" = true ]; then
    echo -e "${YELLOW}--- SHOW CATALOGS ---${NC}"
    docker exec trino trino --execute "SHOW CATALOGS"
    echo ""
    echo -e "${YELLOW}--- SHOW SCHEMAS FROM hive ---${NC}"
    docker exec trino trino --execute "SHOW SCHEMAS FROM hive"
    echo ""
    echo -e "${YELLOW}--- SHOW SCHEMAS FROM iceberg ---${NC}"
    docker exec trino trino --execute "SHOW SCHEMAS FROM iceberg"
    ok "Trino работает"
else
    err "Trino не ответил за 2 минуты. Проверь: docker compose logs trino"
fi

# 6. Итоговый статус
step "Статус контейнеров:"
docker compose ps

echo -e "\n${GREEN}>>> Готово!${NC}"
echo "    Jupyter:       http://localhost:8889"
echo "    Trino:         http://localhost:8080"
echo "    Spark History: http://localhost:18080"
echo "    Airflow:       http://localhost:8081"
echo "    Hue:           http://localhost:8888"
echo "    NameNode UI:    http://localhost:9870"
