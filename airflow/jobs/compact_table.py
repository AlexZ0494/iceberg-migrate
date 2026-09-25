import argparse
from pyspark.sql import SparkSession

parser = argparse.ArgumentParser()
parser.add_argument("--table", required=True)
parser.add_argument("--min-input-files", default="5")
parser.add_argument("--target-file-size-bytes", default="268435456")
args = parser.parse_args()

spark = SparkSession.builder.appName("IcebergCompaction").getOrCreate()

spark.sql(f"""
    CALL iceberg_catalog.system.rewrite_data_files(
        table => '{args.table}',
        options => map(
            'min-input-files', '{args.min_input_files}',
            'target-file-size-bytes', '{args.target_file_size_bytes}'
        )
    )
""")

print(f"Compaction completed for {args.table}")
spark.stop()
