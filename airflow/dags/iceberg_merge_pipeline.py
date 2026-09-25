from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
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
    "email_on_failure": True,
    "email": ["data-alerts@company.com"],
}

with DAG(
    dag_id="iceberg_merge_pipeline",
    default_args=default_args,
    schedule_interval="0 */2 * * *",  # каждые 2 часа
    start_date=datetime(2025, 9, 1),
    catchup=False,
    tags=["iceberg", "merge", "mor"],
) as dag:

    # Шаг 1: инкрементальный MERGE из staging в основную таблицу
    merge_upsert = SparkSubmitOperator(
        task_id="merge_daily_updates",
        application="/opt/airflow/jobs/merge_customer_data.py",
        conf=SPARK_CONF,
        application_args=[
            "--target", "iceberg_catalog.analytics.customer_data",
            "--source", "iceberg_catalog.staging.daily_updates",
            "--date", "{{ ds }}",
        ],
    )

    # Шаг 2: compaction — уплотнение data-файлов и применение delete-файлов
    compact = SparkSubmitOperator(
        task_id="compact_customer_data",
        application="/opt/airflow/jobs/compact_table.py",
        conf=SPARK_CONF,
        application_args=[
            "--table", "iceberg_catalog.analytics.customer_data",
            "--min-input-files", "5",
            "--target-file-size-bytes", "268435456",  # 256 MB
        ],
    )

    # Шаг 3: expire старых снапшотов — освобождаем место на HDFS
    expire_snapshots = SparkSubmitOperator(
        task_id="expire_snapshots",
        application="/opt/airflow/jobs/expire_snapshots.py",
        conf=SPARK_CONF,
        application_args=[
            "--table", "iceberg_catalog.analytics.customer_data",
            "--retention-days", "7",
        ],
    )

    merge_upsert >> compact >> expire_snapshots
