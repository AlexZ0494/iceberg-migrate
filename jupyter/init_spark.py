"""
Преднастроенная SparkSession для работы с Iceberg через Nessie.

Использование:
  %run /home/jovyan/work/init_spark.py              # local mode (быстро, ~3 сек)
  %run /home/jovyan/work/init_spark.py yarn          # YARN mode (30-60 сек)
"""
import sys

MODE = "yarn" if len(sys.argv) > 1 and sys.argv[1] == "yarn" else "local"

from pyspark.sql import SparkSession

if MODE == "yarn":
    spark = (
        SparkSession.builder
        .appName("iceberg_notebook")
        .master("yarn")
        .config("spark.deploy.mode", "client")
        .config("spark.executor.instances", "2")
        .config("spark.executor.cores", "2")
        .config("spark.executor.memory", "2g")
        .config("spark.driver.memory", "1g")
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
        .getOrCreate()
    )
    print("SparkSession создана (YARN mode — 30-60 сек).")
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

print(f"Master: {spark.sparkContext.master}")
