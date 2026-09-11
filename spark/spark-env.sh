#!/bin/bash
export HADOOP_CONF_DIR=/opt/spark/conf
export YARN_CONF_DIR=/opt/spark/conf
export SPARK_HISTORY_OPTS="-Dspark.history.fs.logDirectory=hdfs://namenode:9000/spark-logs"
