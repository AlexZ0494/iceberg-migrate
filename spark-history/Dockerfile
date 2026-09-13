FROM jupyter/pyspark-notebook:spark-3.5.0

USER root

RUN mkdir -p /opt/spark/events

ENV SPARK_HISTORY_OPTS="-Dspark.history.fs.logDirectory=hdfs://namenode:9000/spark-events"

EXPOSE 18080

USER ${NB_UID}

CMD ["/opt/spark/bin/spark-class", "org.apache.spark.deploy.history.HistoryServer"]
