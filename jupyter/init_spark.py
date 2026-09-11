"""
Преднастроенная SparkSession для работы с Iceberg через Nessie на YARN.
Запустите в первой ячейке: %run /home/jovyan/work/init_spark.py
"""
from pyspark.sql import SparkSession

spark = (
    SparkSession.builder
    .appName("iceberg_notebook")
    .master("yarn")
    .config("spark.deploy.mode", "client")
    .config("spark.executor.instances", "2")
    .config("spark.executor.cores", "2")
    .config("spark.executor.memory", "2g")
    .config("spark.driver.memory", "1g")
    # Iceberg + Nessie
    .config("spark.sql.extensions",
            "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
    .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
    .config("spark.sql.catalog.iceberg.catalog-impl",
            "org.apache.iceberg.nessie.NessieCatalog")
    .config("spark.sql.catalog.iceberg.uri", "http://nessie:19120/api/v2")
    .config("spark.sql.catalog.iceberg.ref", "main")
    .config("spark.sql.catalog.iceberg.warehouse", "hdfs://namenode:9000/warehouse")
    .config("spark.sql.defaultCatalog", "iceberg")
    # Логи событий
    .config("spark.eventLog.enabled", "true")
    .config("spark.eventLog.dir", "hdfs://namenode:9000/spark-logs")
    .getOrCreate()
)

print("SparkSession создана. Каталог Iceberg-Nessie готов к работе.")
print(f"Spark UI: {spark.sparkContext.uiWebUrl}")
print(f"Master: {spark.sparkContext.master}")
