import argparse
from pyspark.sql import SparkSession

parser = argparse.ArgumentParser()
parser.add_argument("--target", required=True)
parser.add_argument("--source", required=True)
parser.add_argument("--date", required=True)
args = parser.parse_args()

spark = SparkSession.builder.appName("IcebergMerge").getOrCreate()

# MERGE INTO с тремя ветками: UPDATE, INSERT, и soft-delete по флагу is_deleted
spark.sql(f"""
    MERGE INTO {args.target} AS target
    USING {args.source} AS source
    ON target.id = source.id
    WHEN MATCHED AND source.is_deleted = true THEN DELETE
    WHEN MATCHED THEN UPDATE SET
        target.name         = source.name,
        target.email        = source.email,
        target.last_updated = current_timestamp()
    WHEN NOT MATCHED AND source.is_deleted = false THEN INSERT
        (id, name, email, last_updated)
        VALUES (source.id, source.name, source.email, current_timestamp())
""")

# Проверка: сколько строк было затронуто
count = spark.sql(f"SELECT COUNT(*) FROM {args.target}").collect()[0][0]
print(f"Rows in {args.target} after merge: {count}")

spark.stop()
