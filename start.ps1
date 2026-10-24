# start.ps1 — автозапуск big data кластера (Windows)
# Запуск: powershell -ExecutionPolicy Bypass -File .\start.ps1
#
# Аргументы:
#   .\start.ps1          — запустить кластер
#   .\start.ps1 stop     — остановить кластер
#   .\start.ps1 restart  — перезапустить кластер
#   .\start.ps1 logs     — показать логи
#   .\start.ps1 status   — показать статус

$ErrorActionPreference = "Stop"

function Write-Step($msg) { Write-Host "`n>>> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "    [WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "    [ERR] $msg" -ForegroundColor Red }
function Write-Info($msg) { Write-Host "    [INFO] $msg" -ForegroundColor Blue }

# ──────────────────────────────────────────────
# Проверка Docker
# ──────────────────────────────────────────────
function Test-Docker {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Err "Docker не установлен. Установите Docker Desktop: https://docs.docker.com/desktop/windows/install/"
        exit 1
    }

    try {
        docker info | Out-Null
    } catch {
        Write-Warn "Docker не отвечает. Перезапустите Docker Desktop."
        exit 1
    }
}

# ──────────────────────────────────────────────
# Запуск кластера
# ──────────────────────────────────────────────
function Start-Cluster {
    Test-Docker

    Write-Step "Остановка старых контейнеров..."
    docker compose down --remove-orphans 2>$null
    Write-Ok "Старые контейнеры остановлены"

    Write-Step "Сборка и запуск контейнеров..."
    docker compose up -d --build
    Write-Ok "Контейнеры запущены"

    Write-Step "Ожидание NameNode (до 3 минут)..."
    $ready = $false
    for ($i = 0; $i -lt 36; $i++) {
        try {
            $result = docker exec namenode /opt/hadoop/bin/hdfs dfs -ls / 2>$null
            if ($LASTEXITCODE -eq 0) { $ready = $true; break }
        } catch { }
        Start-Sleep -Seconds 5
    }
    if (-not $ready) {
        Write-Err "NameNode не поднялся за 3 минуты"
        docker compose logs namenode
        exit 1
    }
    Write-Ok "NameNode готов"

    Write-Step "Создание директорий в HDFS..."
    docker exec namenode /opt/hadoop/bin/hdfs dfs -mkdir -p /user/hive/warehouse
    docker exec namenode /opt/hadoop/bin/hdfs dfs -mkdir -p /warehouse
    docker exec namenode /opt/hadoop/bin/hdfs dfs -mkdir -p /spark-events
    docker exec namenode /opt/hadoop/bin/hdfs dfs -chmod -R 777 /user/hive /warehouse /spark-events
    Write-Ok "HDFS-директории созданы"

    Write-Step "Ожидание сервисов (до 2 минут)..."
    Start-Sleep -Seconds 15

    # Проверяем Trino через HTTP
    $trinoReady = $false
    for ($i = 0; $i -lt 24; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8082/v1/statement" -Method Post -Body '{}' -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) { $trinoReady = $true; break }
        } catch { }
        Start-Sleep -Seconds 5
    }

    if ($trinoReady) {
        Write-Ok "Trino готов"
    } else {
        Write-Warn "Trino не ответил за 2 минуты. Проверь: docker compose logs trino"
    }

    # Проверяем Hue
    $hueReady = $false
    for ($i = 0; $i -lt 12; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8888/" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($response.StatusCode -in @(200, 302, 303)) { $hueReady = $true; break }
        } catch { }
        Start-Sleep -Seconds 10
    }

    if ($hueReady) {
        Write-Ok "Hue готов"
    } else {
        Write-Warn "Hue не ответил. Проверь: docker compose logs hue"
    }

    # Итоговый статус
    Write-Step "Статус контейнеров:"
    docker compose ps --format "table {{.Name}}`t{{.Status}}`t{{.Ports}}"

    Write-Host ""
    Write-Host ">>> Готово!" -ForegroundColor Green
    Write-Host ""
    Write-Host "    Jupyter:       http://localhost:8889/lab" -ForegroundColor White
    Write-Host "    Hue:           http://localhost:8888" -ForegroundColor White
    Write-Host "    Trino UI:      http://localhost:8082" -ForegroundColor White
    Write-Host "    YARN:          http://localhost:8088" -ForegroundColor White
    Write-Host "    Spark History: http://localhost:18080" -ForegroundColor White
    Write-Host "    HDFS UI:       http://localhost:9870" -ForegroundColor White
    Write-Host "    Nessie UI:     http://localhost:19120" -ForegroundColor White
    Write-Host ""
    Write-Host "SQL-скрипты:" -ForegroundColor Yellow
    Write-Host "  Hue:  jupyter/work/05_visualization_hue.sql" -ForegroundColor Yellow
    Write-Host "  Trino: jupyter/work/06_visualization_trino.sql" -ForegroundColor Yellow
    Write-Host "  Hive:  jupyter/work/07_visualization_hive.sql" -ForegroundColor Yellow
    Write-Host ""
}

# ──────────────────────────────────────────────
# Остановка кластера
# ──────────────────────────────────────────────
function Stop-Cluster {
    Write-Step "Остановка кластера..."
    docker compose down
    Write-Ok "Кластер остановлен"
}

# ──────────────────────────────────────────────
# Перезапуск
# ──────────────────────────────────────────────
function Restart-Cluster {
    Stop-Cluster
    Start-Sleep -Seconds 5
    Start-Cluster
}

# ──────────────────────────────────────────────
# Логи
# ──────────────────────────────────────────────
function Show-Logs {
    param($Service)
    if ($Service) {
        docker compose logs -f $Service
    } else {
        docker compose logs -f
    }
}

# ──────────────────────────────────────────────
# Статус
# ──────────────────────────────────────────────
function Show-Status {
    Write-Host "`nСтатус контейнеров:" -ForegroundColor Cyan
    docker compose ps --format "table {{.Name}}`t{{.Image}}`t{{.Status}}`t{{.Ports}}"

    Write-Host "`nБыстрые проверки:" -ForegroundColor Cyan

    # NameNode
    try {
        docker exec namenode /opt/hadoop/bin/hdfs dfs -ls / 2>$null | Out-Null
        Write-Ok "NameNode: OK"
    } catch {
        Write-Err "NameNode: FAILED"
    }

    # Trino
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8082/v1/statement" -Method Post -Body '{}' -TimeoutSec 2 -ErrorAction SilentlyContinue
        Write-Ok "Trino: OK"
    } catch {
        Write-Err "Trino: FAILED"
    }

    # Hue
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8888/" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
        Write-Ok "Hue: OK"
    } catch {
        Write-Err "Hue: FAILED"
    }

    # Nessie
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:19120/api/v2/refs/branches/main" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
        Write-Ok "Nessie: OK"
    } catch {
        Write-Err "Nessie: FAILED"
    }
}

# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────
$command = if ($args.Count -gt 0) { $args[0].ToLower() } else { "start" }

switch ($command) {
    "start" { Start-Cluster }
    "stop"  { Stop-Cluster }
    "restart" { Restart-Cluster }
    "logs"  { Show-Logs -Service $(if ($args.Count -gt 1) { $args[1] }) }
    "status" { Show-Status }
    "clean" {
        Write-Step "Удаление всех контейнеров и томов..."
        docker compose down -v --remove-orphans
        Write-Ok "Все данные удалены"
    }
    default {
        Write-Host "`nBig Data Cluster — Script" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Usage: .\start.ps1 {start|stop|restart|logs|status|clean|help}" -ForegroundColor White
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Yellow
        Write-Host "  start     Запустить кластер (по умолчанию)" -ForegroundColor White
        Write-Host "  stop      Остановить кластер" -ForegroundColor White
        Write-Host "  restart   Перезапустить кластер" -ForegroundColor White
        Write-Host "  logs [svc] Показать логи (опционально: namenode, datanode, trino, hue, jupyter, etc.)" -ForegroundColor White
        Write-Host "  status    Показать статус всех сервисов" -ForegroundColor White
        Write-Host "  clean     Удалить все контейнеры и тома" -ForegroundColor White
        Write-Host "  help      Показать эту справку" -ForegroundColor White
        Write-Host ""
        Write-Host "Services:" -ForegroundColor Yellow
        Write-Host "  Jupyter:       http://localhost:8889" -ForegroundColor White
        Write-Host "  Hue:           http://localhost:8888" -ForegroundColor White
        Write-Host "  Trino:         http://localhost:8082" -ForegroundColor White
        Write-Host "  YARN:          http://localhost:8088" -ForegroundColor White
        Write-Host "  Spark History: http://localhost:18080" -ForegroundColor White
        Write-Host "  HDFS UI:       http://localhost:9870" -ForegroundColor White
        Write-Host "  Nessie:        http://localhost:19120" -ForegroundColor White
        Write-Host ""
    }
}
