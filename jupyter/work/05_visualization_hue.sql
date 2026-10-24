-- =====================================================
-- Визуализация результатов миграции Hive -> Iceberg
-- Для использования в Hue (http://localhost:8888)
-- =====================================================

-- 1. Показываем созданные базы данных
SHOW DATABASES;

-- 2. Hive Classic: статистика
SELECT 
    'hive_classic' as catalog,
    COUNT(*) as total_records,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT region) as regions,
    SUM(amount) as total_amount,
    MIN(dt) as min_date,
    MAX(dt) as max_date
FROM hive_classic.orders;

-- 3. Iceberg Modern: статистика
SELECT 
    'iceberg_modern' as catalog,
    COUNT(*) as total_records,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT region) as regions,
    SUM(amount) as total_amount,
    MIN(dt) as min_date,
    MAX(dt) as max_date
FROM iceberg_modern.orders;

-- 4. Сравнение по регионам
SELECT 
    region,
    COUNT(*) as total_records,
    SUM(amount) as total_amount,
    AVG(amount) as avg_amount
FROM iceberg_modern.orders
GROUP BY region
ORDER BY total_amount DESC;

-- 5. Статистика по статусам
SELECT 
    status,
    COUNT(*) as cnt,
    SUM(amount) as total_amount
FROM iceberg_modern.orders
GROUP BY status
ORDER BY cnt DESC;

-- 6. Топ пользователей по сумме заказов
SELECT 
    user_id,
    COUNT(*) as order_count,
    SUM(amount) as total_amount
FROM iceberg_modern.orders
GROUP BY user_id
ORDER BY total_amount DESC
LIMIT 20;

-- 7. Распределение заказов по датам
SELECT 
    dt,
    COUNT(*) as order_count,
    SUM(amount) as daily_total
FROM iceberg_modern.orders
GROUP BY dt
ORDER BY dt;

-- 8. Сравнение количества записей
SELECT 
    'hive_classic' as db_name,
    COUNT(*) as record_count
FROM hive_classic.orders
UNION ALL
SELECT 
    'iceberg_modern' as db_name,
    COUNT(*) as record_count
FROM iceberg_modern.orders;
