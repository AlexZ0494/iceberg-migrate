"""
Преднастроенная SparkSession для работы с Iceberg через Nessie.

Использование:
  %run /home/jovyan/work/init_spark.py              # local mode (быстро, ~3 сек)
  %run /home/jovyan/work/init_spark.py yarn          # YARN mode (30-60 сек)

ВАЖНО: Если SparkSession уже создана (local mode), нужно сначала выполнить:
  spark.stop()
  del spark
  gc.collect()
  
Затем запустить:
  %run /home/jovyan/work/init_spark.py yarn
"""
import sys
import gc

# Останавливаем существующий SparkContext если есть
try:
    from pyspark import SparkContext
    if SparkContext._active_spark_context:
        print("⚠️ Остановка существующего SparkContext...")
        SparkContext.getActive().stop()
        print("✅ Существующий SparkContext остановлен")
except Exception:
    pass

# Очищаем garbage
gc.collect()

MODE = "yarn" if len(sys.argv) > 1 and sys.argv[1] == "yarn" else "local"

from pyspark.sql import SparkSession

if MODE == "yarn":
    spark = (
        SparkSession.builder
        .appName("iceberg_notebook")
        .master("yarn")
        .config("spark.deploy.mode", "client")
        .config("spark.executor.instances", "1")
        .config("spark.executor.cores", "1")
        .config("spark.executor.memory", "512m")
        .config("spark.driver.memory", "512m")
        .config("spark.sql.extensions",
                "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
        .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
        .config("spark.sql.catalog.iceberg.catalog-impl",
                "org.apache.iceberg.nessie.NessieCatalog")
        .config("spark.sql.catalog.iceberg.uri", "http://nessie:19120/api/v2")
        .config("spark.sql.catalog.iceberg.ref", "main")
        .config("spark.sql.catalog.iceberg.warehouse", "hdfs://namenode:9000/warehouse")
        .config("spark.sql.defaultCatalog", "iceberg")
        .config("spark.eventLog.enabled", "true")
        .config("spark.eventLog.dir", "hdfs://namenode:9000/spark-logs")
        # Spark UI configuration for YARN
        .config("spark.ui.showConsoleProgress", False)
        .config("spark.yarn.admin.ttl", "0")
        .getOrCreate()
    )
    print("SparkSession создана (YARN mode — 30-60 сек).")
    # Для YARN mode uiWebUrl = None, получаем URL из YARN ResourceManager
    app_id = spark.sparkContext.applicationId
    yarn_ui_url = f"http://localhost:8088/proxy/{app_id}/"
    print(f"Spark UI: {yarn_ui_url}")
else:
    spark = (
        SparkSession.builder
        .appName("iceberg_notebook")
        .master("local[*]")
        .config("spark.sql.extensions",
                "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
        .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
        .config("spark.sql.catalog.iceberg.catalog-impl",
                "org.apache.iceberg.nessie.NessieCatalog")
        .config("spark.sql.catalog.iceberg.uri", "http://nessie:19120/api/v2")
        .config("spark.sql.catalog.iceberg.ref", "main")
        .config("spark.sql.catalog.iceberg.warehouse", "hdfs://namenode:9000/warehouse")
        .config("spark.sql.defaultCatalog", "iceberg")
        .getOrCreate()
    )
    print("SparkSession создана (local mode — ~3 сек).")
    print(f"Spark UI: {spark.sparkContext.uiWebUrl or 'Not available yet'}")

print(f"Master: {spark.sparkContext.master}")
