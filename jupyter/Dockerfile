FROM jupyter/pyspark-notebook:latest

USER root

RUN apt-get update && apt-get install -y wget procps netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

# Iceberg JAR
RUN mkdir -p /usr/local/spark/jars && \
    wget -q -O /usr/local/spark/jars/iceberg-spark-runtime-3.5_2.12-1.5.2.jar \
    https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.5.2/iceberg-spark-runtime-3.5_2.12-1.5.2.jar || true

# Nessie JAR (для Spark-Nessie интеграции)
RUN wget -q -O /usr/local/spark/jars/nessie-0.92.1.jar \
    https://repo1.maven.org/maven2/org/projectnessie/nessie/0.92.1/nessie-0.92.1.jar || true

# Скачиваем Hadoop client для работы с YARN
RUN wget -q -O /tmp/hadoop.tar.gz https://archive.apache.org/dist/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz && \
    tar -xzf /tmp/hadoop.tar.gz -C /opt && \
    mv /opt/hadoop-3.3.6 /opt/hadoop && \
    rm /tmp/hadoop.tar.gz && \
    chmod -R 755 /opt/hadoop

ENV PATH=${PATH}:/opt/hadoop/bin:/opt/hadoop/sbin
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV SPARK_HOME=/usr/local/spark
ENV PYSPARK_PYTHON=python3
ENV PYSPARK_DRIVER_PYTHON=python3

# Преднастроенный init-скрипт для SparkSession
COPY --chown=${NB_UID}:${NB_GID} init_spark.py /home/jovyan/work/init_spark.py

# Отключаем токен, разрешаем вход без пароля
RUN pip install jupyter_server 2>/dev/null || true

USER ${NB_UID}
