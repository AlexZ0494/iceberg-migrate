from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("CreateIcebergOrders").getOrCreate()

spark.sql("""
    CREATE TABLE IF NOT EXISTS iceberg_catalog.silver.orders (
        order_id    STRING,
        user_id     STRING,
        amount      DECIMAL(18,2),
        created_at  TIMESTAMP
    ) USING iceberg
    PARTITIONED BY (days(created_at), bucket(16, user_id))
    LOCATION 'hdfs://namenode:8020/warehouse/silver/orders'
""")

spark.sql("""
    ALTER TABLE iceberg_catalog.silver.orders
    SET TBLPROPERTIES ('format-version' = '2', 'write.format.default' = 'parquet')
""")

print("Table silver.orders created successfully.")
spark.stop()
