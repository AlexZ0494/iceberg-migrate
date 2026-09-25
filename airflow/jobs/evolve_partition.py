import argparse
from pyspark.sql import SparkSession

parser = argparse.ArgumentParser()
parser.add_argument("--table", required=True)
parser.add_argument("--new-spec", required=True)
args = parser.parse_args()

spark = SparkSession.builder.appName("EvolvePartitionSpec").getOrCreate()

# Сравниваем текущую и новую спецификацию
current = spark.sql(f"SHOW PARTITIONS iceberg_catalog.{args.table}")
print(f"Current partition spec: {current}")

# Эволюция — Iceberg перепишет только metadata
spark.sql(f"""
    ALTER TABLE iceberg_catalog.{args.table}
    SET PARTITION SPEC ({args.new_spec})
""")

print(f"Partition spec updated to: {args.new_spec}")
spark.stop()
