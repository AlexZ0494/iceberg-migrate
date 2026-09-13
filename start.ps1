# start.ps1 — автозапуск big data кластера
# Запуск: powershell -ExecutionPolicy Bypass -File .\start.ps1

$ErrorActionPreference = "Stop"

function Write-Step($msg) { Write-Host "`n>>> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    OK: $msg" -ForegroundColor Green }
function Write-Err($msg)  { Write-Host "    ERROR: $msg" -ForegroundColor Red }

# 1. Запуск Docker Compose
Write-Step "Сборка и запуск контейнеров..."
docker compose up -d --build
if ($LASTEXITCODE -ne 0) { Write-Err "Docker Compose не смог стартовать"; exit 1 }
Write-Ok "Контейнеры запущены"

# 2. Ждём, пока NameNode поднимется
Write-Step "Ожидание NameNode (до 3 минут)..."
$ready = $false
for ($i = 0; $i -lt 36; $i++) {
    $status = docker inspect --format='{{.State.Running}}' namenode 2>$null
    if ($status -eq "true") {
        $hdfs = docker exec namenode hdfs dfs -ls / 2>$null
        if ($LASTEXITCODE -eq 0) { $ready = $true; break }
    }
    Start-Sleep -Seconds 5
}
if (!$ready) {
    Write-Err "NameNode не поднялся за 3 минуты. Проверь: docker compose logs namenode"
    docker compose ps
    exit 1
}
Write-Ok "NameNode готов"

# 3. Создать Hive-директории в HDFS
Write-Step "Создание директорий в HDFS..."
docker exec namenode hdfs dfs -mkdir -p /user/hive/warehouse
docker exec namenode hdfs dfs -mkdir -p /warehouse
docker exec namenode hdfs dfs -mkdir -p /spark-events
docker exec namenode hdfs dfs -chmod -R 777 /user/hive /warehouse /spark-events
Write-Ok "HDFS-директории созданы"

# 4. Ждём Trino
Write-Step "Ожидание Trino (до 2 минут)..."
$trinoReady = $false
for ($i = 0; $i -lt 24; $i++) {
    $result = docker exec trino trino --execute "SHOW CATALOGS" 2>$null
    if ($LASTEXITCODE -eq 0) { $trinoReady = $true; break }
    Start-Sleep -Seconds 5
}

# 5. Проверка Trino
Write-Step "Проверка Trino..."
if ($trinoReady) {
    Write-Host "--- SHOW CATALOGS ---" -ForegroundColor Yellow
    docker exec trino trino --execute "SHOW CATALOGS"
    Write-Host "`n--- SHOW SCHEMAS FROM hive ---" -ForegroundColor Yellow
    docker exec trino trino --execute "SHOW SCHEMAS FROM hive"
    Write-Host "`n--- SHOW SCHEMAS FROM iceberg ---" -ForegroundColor Yellow
    docker exec trino trino --execute "SHOW SCHEMAS FROM iceberg"
    Write-Ok "Trino работает"
} else {
    Write-Err "Trino не ответил за 2 минуты. Проверь: docker compose logs trino"
}

# 6. Итоговый статус
Write-Step "Статус контейнеров:"
docker compose ps

Write-Host "`n>>> Готово!" -ForegroundColor Green
Write-Host "    Jupyter:       http://localhost:8889"
Write-Host "    Trino:         http://localhost:8080"
Write-Host "    Spark History: http://localhost:18080"
Write-Host "    Airflow:       http://localhost:8081"
Write-Host "    Hue:           http://localhost:8888"
Write-Host "    NameNode UI:    http://localhost:9870"
