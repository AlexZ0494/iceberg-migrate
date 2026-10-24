-- =====================================================
-- Визуализация через Hive Server2
-- Для использования в Hue с Hive Server2 (port 10000)
-- =====================================================

-- 1. Показываем базы данных
SHOW DATABASES;

-- 2. Hive Classic: полная статистика
SELECT 
    'hive_classic' as catalog_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT region) as regions,
    SUM(amount) as total_amount,
    MIN(dt) as first_date,
    MAX(dt) as last_date
FROM hive_classic.orders;

-- 3. Статистика по регионам в Hive
SELECT 
    region,
    COUNT(*) as order_count,
    SUM(amount) as total_amount,
    AVG(amount) as avg_amount
FROM hive_classic.orders
GROUP BY region
ORDER BY total_amount DESC;

-- 4. Статистика по статусам
SELECT 
    status,
    COUNT(*) as record_count,
    SUM(amount) as amount_total
FROM hive_classic.orders
GROUP BY status;

-- 5. Топ пользователей
SELECT 
    user_id,
    COUNT(*) as num_orders,
    SUM(amount) as total_spent
FROM hive_classic.orders
GROUP BY user_id
ORDER BY total_spent DESC
LIMIT 20;

-- 6. Распределение по дням
SELECT 
    dt,
    COUNT(*) as daily_count,
    SUM(amount) as daily_total
FROM hive_classic.orders
GROUP BY dt
ORDER BY dt;

-- 7. Сравнение Hive vs Iceberg
SELECT 
    'hive_classic' as database_name,
    COUNT(*) as record_count
FROM hive_classic.orders
UNION ALL
SELECT 
    'iceberg_modern',
    COUNT(*)
FROM iceberg_modern.orders;
