from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta

SPARK_CONF = {
    "spark.sql.extensions": "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions",
    "spark.sql.catalog.iceberg_catalog": "org.apache.iceberg.spark.SparkCatalog",
    "spark.sql.catalog.iceberg_catalog.type": "hadoop",
    "spark.sql.catalog.iceberg_catalog.warehouse": "hdfs://namenode:8020/warehouse",
    "spark.hadoop.fs.defaultFS": "hdfs://namenode:8020",
}

default_args = {
    "owner": "data-engineering",
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="iceberg_table_setup",
    default_args=default_args,
    schedule_interval=None,  # запускается вручную или по триггеру
    start_date=datetime(2025, 9, 1),
    catchup=False,
    tags=["iceberg", "ddl"],
) as dag:

    # Шаг 1: создание таблицы со скрытым партиционированием
    create_table = SparkSubmitOperator(
        task_id="create_orders_table",
        application="/opt/airflow/jobs/create_orders_table.py",
        conf=SPARK_CONF,
        application_args=[
            "--table", "silver.orders",
            "--location", "hdfs://namenode:8020/warehouse/silver/orders",
        ],
    )

    # Шаг 2: эволюция партиций — переключение с daily на hourly
    evolve_partition = SparkSubmitOperator(
        task_id="evolve_partition_spec",
        application="/opt/airflow/jobs/evolve_partition.py",
        conf=SPARK_CONF,
        application_args=[
            "--table", "silver.orders",
            "--new-spec", "hours(created_at), bucket(16, region)",
        ],
    )

    create_table >> evolve_partition
