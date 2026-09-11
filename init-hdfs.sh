#!/bin/bash
# Создаёт директории в HDFS для Spark и Iceberg
docker exec namenode hdfs dfs -mkdir -p /spark-logs
docker exec namenode hdfs dfs -mkdir -p /warehouse
docker exec namenode hdfs dfs -mkdir -p /spark-jars
docker exec namenode hdfs dfs -chmod -R 777 /warehouse
docker exec namenode hdfs dfs -chmod -R 777 /spark-logs
echo "HDFS-директории созданы."
