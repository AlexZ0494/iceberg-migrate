-- =====================================================
-- Визуализация Iceberg через Trino
-- Для использования в Trino (http://localhost:8082)
-- =====================================================

-- 1. Подключение к Iceberg каталогу (через Nessie)
-- В Trino каталог iceberg подключён через iceberg.properties

-- 2. Показываем таблицы Iceberg
SHOW SCHEMAS FROM iceberg;
SHOW TABLES FROM iceberg.iceberg_modern;

-- 3. Статистика по Iceberg таблицам
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT region) as regions,
    SUM(amount) as total_amount,
    MIN(dt) as min_date,
    MAX(dt) as max_date
FROM iceberg.iceberg_modern.orders;

-- 4. Анализ по регионам
SELECT 
    region,
    COUNT(*) as order_count,
    SUM(amount) as total_amount,
    AVG(amount) as avg_order_value,
    MIN(amount) as min_order,
    MAX(amount) as max_order
FROM iceberg.iceberg_modern.orders
GROUP BY region
ORDER BY total_amount DESC;

-- 5. Динамические дашборды: тренды по дням
SELECT 
    dt,
    COUNT(*) as daily_orders,
    SUM(amount) as daily_revenue,
    ROUND(SUM(amount) / COUNT(*), 2) as avg_order_value
FROM iceberg.iceberg_modern.orders
GROUP BY dt
ORDER BY dt;

-- 6. Топ пользователей
SELECT 
    user_id,
    COUNT(*) as total_orders,
    SUM(amount) as total_spent,
    AVG(amount) as avg_order,
    MIN(dt) as first_order,
    MAX(dt) as last_order
FROM iceberg.iceberg_modern.orders
GROUP BY user_id
ORDER BY total_spent DESC
LIMIT 50;

-- 7. Конверсия по статусам
SELECT 
    status,
    COUNT(*) as cnt,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM iceberg.iceberg_modern.orders
GROUP BY status
ORDER BY cnt DESC;

-- 8. Time Travel: история изменений
SELECT 
    snapshot_id,
    committed_at,
    operation,
    num_added_files,
    num_deleted_files,
    num_added_rows,
    num_deleted_rows
FROM iceberg.iceberg_modern.orders$history
ORDER BY committed_at;

-- 9. Time Travel: данные до последнего изменения
-- Берём первый снапшот
SELECT *
FROM iceberg.iceberg_modern.orders
FOR SYSTEM_VERSION AS OF (
    SELECT snapshot_id 
    FROM iceberg.iceberg_modern.orders$history 
    ORDER BY committed_at 
    LIMIT 1
)
LIMIT 10;

-- 10. Schema Evolution: проверка схемы
DESCRIBE iceberg.iceberg_modern.orders;
