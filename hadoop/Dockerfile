FROM eclipse-temurin:11-jdk

ENV HADOOP_VERSION=3.3.6
ENV HADOOP_HOME=/opt/hadoop
ENV JAVA_HOME=/opt/java/openjdk
ENV HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop

RUN apt-get update && apt-get install -y wget curl procps && \
    wget -q https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C /opt/ && \
    mv /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} && \
    rm hadoop-${HADOOP_VERSION}.tar.gz && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PATH=$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin

# ТОЛЬКО core и hdfs — этого достаточно для HDFS
COPY conf/core-site.xml ${HADOOP_CONF_DIR}/core-site.xml
COPY conf/hdfs-site.xml ${HADOOP_CONF_DIR}/hdfs-site.xml

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
