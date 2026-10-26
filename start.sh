#!/bin/bash
# start.sh — автозапуск big data кластера
# Запуск: chmod +x start.sh && ./start.sh
#
# Аргументы:
#   ./start.sh          — запустить кластер
#   ./start.sh stop     — остановить кластер
#   ./start.sh restart  — перезапустить кластер
#   ./start.sh logs     — показать логи
#   ./start.sh status   — показать статус

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

step()  { echo -e "\n${CYAN}${BOLD}>>> $1${NC}"; }
ok()    { echo -e "    ${GREEN}✓${NC} $1"; }
warn()  { echo -e "    ${YELLOW}⚠${NC} $1"; }
err()   { echo -e "    ${RED}✗${NC} $1"; }
info()  { echo -e "    ${BLUE}ℹ${NC} $1"; }

# ──────────────────────────────────────────────
# Проверка Docker
# ──────────────────────────────────────────────
check_docker() {
    if ! command -v docker &>/dev/null; then
        err "Docker не установлен. Установите Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi

    if ! docker info &>/dev/null; then
        warn "Docker не отвечает. Перезапустите Docker Desktop или демон."
        exit 1
    fi

    # Проверяем членство в группе docker
    if ! id -nG 2>/dev/null | grep -qw docker; then
        warn "Пользователь '$USER' не в группе 'docker'"
        info "Выполните: sudo usermod -aG docker $USER && newgrp docker"
        info "Затем перезапустите терминал и запустите скрипт снова"
        exit 1
    fi
}

# ──────────────────────────────────────────────
# Запуск кластера
# ──────────────────────────────────────────────
start_cluster() {
    check_docker

    step "Остановка старых контейнеров..."
    docker compose down --remove-orphans 2>/dev/null || true
    ok "Старые контейнеры остановлены"

    step "Сборка и запуск контейнеров..."
    docker compose up -d --build
    ok "Контейнеры запущены"

    step "Ожидание NameNode (до 3 минут)..."
    ready=false
    for i in $(seq 1 36); do
        if docker exec namenode /opt/hadoop/bin/hdfs dfs -ls / >/dev/null 2>&1; then
            ready=true
            break
        fi
        sleep 5
    done
    if [ "$ready" = false ]; then
        err "NameNode не поднялся за 3 минуты"
        docker compose logs namenode
        exit 1
    fi
    ok "NameNode готов"

    step "Создание директорий в HDFS..."
    docker exec namenode /opt/hadoop/bin/hdfs dfs -mkdir -p /user/hive/warehouse
    docker exec namenode /opt/hadoop/bin/hdfs dfs -mkdir -p /warehouse
    docker exec namenode /opt/hadoop/bin/hdfs dfs -mkdir -p /spark-events
    docker exec namenode /opt/hadoop/bin/hdfs dfs -mkdir -p /spark-logs
    docker exec namenode /opt/hadoop/bin/hdfs dfs -chmod -R 777 /user/hive /warehouse /spark-events /spark-logs
    ok "HDFS-директории созданы"

    step "Ожидание HDFS SafeMode (до 2 минут)..."
    safe_mode=false
    for i in $(seq 1 24); do
        safe_mode=$(docker exec namenode /opt/hadoop/bin/hdfs dfsadmin -safemode get 2>/dev/null | grep -o "Safe mode is off" || true)
        if [ "$safe_mode" = "Safe mode is off" ]; then
            break
        fi
        sleep 5
    done
    ok "HDFS SafeMode: off"

    step "Ожидание YARN (до 2 минут)..."
    sleep 10

    # Проверяем Trino через HTTP
    trino_ready=false
    for i in $(seq 1 24); do
        if curl -s http://localhost:8082/v1/statement >/dev/null 2>&1; then
            trino_ready=true
            break
        fi
        sleep 5
    done

    if [ "$trino_ready" = true ]; then
        ok "Trino готов"
    else
        warn "Trino не ответил за 2 минуты. Проверь: docker compose logs trino"
    fi

    # Проверяем Hue
    hue_ready=false
    for i in $(seq 1 12); do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/ | grep -qE "30[23]|200"; then
            hue_ready=true
            break
        fi
        sleep 10
    done

    if [ "$hue_ready" = true ]; then
        ok "Hue готов"
    else
        warn "Hue не ответил. Проверь: docker compose logs hue"
    fi

    # Проверяем YARN
    yarn_ready=false
    for i in $(seq 1 12); do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8088/ | grep -qE "30[23]|200"; then
            yarn_ready=true
            break
        fi
        sleep 10
    done

    if [ "$yarn_ready" = true ]; then
        ok "YARN RM готов"
    else
        warn "YARN RM не ответил. Проверь: docker compose logs resourcemanager"
    fi

    # Проверяем Spark History
    spark_hist_ready=false
    for i in $(seq 1 12); do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:18080/ | grep -qE "30[23]|200"; then
            spark_hist_ready=true
            break
        fi
        sleep 10
    done

    if [ "$spark_hist_ready" = true ]; then
        ok "Spark History готов"
    else
        warn "Spark History не ответил. Проверь: docker compose logs spark-history"
    fi

    # Итоговый статус
    step "Статус контейнеров:"
    docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

    echo ""
    echo -e "${GREEN}${BOLD}>>> Готово!${NC}"
    echo ""
    echo -e "    ${BOLD}Jupyter:${NC}       http://localhost:8889/lab"
    echo -e "    ${BOLD}Hue:${NC}           http://localhost:8888"
    echo -e "    ${BOLD}Trino UI:${NC}      http://localhost:8082"
    echo -e "    ${BOLD}YARN:${NC}          http://localhost:8088"
    echo -e "    ${BOLD}Spark History:${NC} http://localhost:18080"
    echo -e "    ${BOLD}HDFS UI:${NC}       http://localhost:9870"
    echo -e "    ${BOLD}Nessie UI:${NC}     http://localhost:19120"
    echo ""
}

# ──────────────────────────────────────────────
# Остановка кластера
# ──────────────────────────────────────────────
stop_cluster() {
    step "Остановка кластера..."
    docker compose down
    ok "Кластер остановлен"
}

# ──────────────────────────────────────────────
# Перезапуск
# ──────────────────────────────────────────────
restart_cluster() {
    stop_cluster
    sleep 5
    start_cluster
}

# ──────────────────────────────────────────────
# Логи
# ──────────────────────────────────────────────
show_logs() {
    if [ -n "$1" ]; then
        docker compose logs -f "$1"
    else
        docker compose logs -f
    fi
}

# ──────────────────────────────────────────────
# Статус
# ──────────────────────────────────────────────
show_status() {
    echo -e "${BOLD}Статус контейнеров:${NC}"
    docker compose ps --format "table {{.Name}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

    echo ""
    echo -e "${BOLD}Быстрые проверки:${NC}"

    # NameNode
    if docker exec namenode /opt/hadoop/bin/hdfs dfs -ls / >/dev/null 2>&1; then
        ok "NameNode: OK"
    else
        err "NameNode: FAILED"
    fi

    # Trino
    if curl -s http://localhost:8082/v1/statement >/dev/null 2>&1; then
        ok "Trino: OK"
    else
        err "Trino: FAILED"
    fi

    # Hue
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/ | grep -qE "30[23]|200"; then
        ok "Hue: OK"
    else
        err "Hue: FAILED"
    fi

    # Nessie
    if curl -s http://localhost:19120/api/v2/refs/branches/main >/dev/null 2>&1; then
        ok "Nessie: OK"
    else
        err "Nessie: FAILED"
    fi
}

# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────
case "${1:-start}" in
    start)
        start_cluster
        ;;
    stop)
        stop_cluster
        ;;
    restart)
        restart_cluster
        ;;
    logs)
        show_logs "${2:-}"
        ;;
    status)
        show_status
        ;;
    clean)
        step "Удаление всех контейнеров и томов..."
        docker compose down -v --remove-orphans
        ok "Все данные удалены"
        ;;
    help|*)
        echo -e "${BOLD}Big Data Cluster — Script${NC}"
        echo ""
        echo "Usage: $0 {start|stop|restart|logs|status|clean|help}"
        echo ""
        echo "Commands:"
        echo "  start     Запустить кластер (по умолчанию)"
        echo "  stop      Остановить кластер"
        echo "  restart   Перезапустить кластер"
        echo "  logs [svc] Показать логи (опционально: namenode, datanode, trino, hue, jupyter, etc.)"
        echo "  status    Показать статус всех сервисов"
        echo "  clean     Удалить все контейнеры и тома"
        echo "  help      Показать эту справку"
        echo ""
        echo "Services:"
        echo "  Jupyter:       http://localhost:8889"
        echo "  Hue:           http://localhost:8888"
        echo "  Trino:         http://localhost:8082"
        echo "  YARN:          http://localhost:8088"
        echo "  Spark History: http://localhost:18080"
        echo "  HDFS UI:       http://localhost:9870"
        echo "  Nessie:        http://localhost:19120"
        ;;
esac
