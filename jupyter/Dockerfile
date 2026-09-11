FROM jupyter/pyspark-notebook:latest

USER root

RUN apt-get update && apt-get install -y wget procps && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/spark/jars && \
    wget -q -O /usr/local/spark/jars/iceberg-spark-runtime-3.5_2.12-1.5.2.jar \
    https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.5.2/iceberg-spark-runtime-3.5_2.12-1.5.2.jar || true

ENV HADOOP_CONF_DIR=/etc/hadoop/conf
ENV SPARK_HOME=/usr/local/spark
ENV PYSPARK_PYTHON=python3
ENV PYSPARK_DRIVER_PYTHON=python3

USER ${NB_UID}
