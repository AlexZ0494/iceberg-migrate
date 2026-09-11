FROM eclipse-temurin:11-jdk

ENV HADOOP_VERSION=3.3.6
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH=$PATH:/opt/hadoop/bin:/opt/hadoop/sbin

RUN apt-get update && apt-get install -y wget ssh pdsh procps && \
    rm -rf /var/lib/apt/lists/* && \
    wget -q https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz -O /tmp/hadoop.tar.gz && \
    tar -xzf /tmp/hadoop.tar.gz -C /opt/ && \
    mv /opt/hadoop-${HADOOP_VERSION} /opt/hadoop && \
    rm /tmp/hadoop.tar.gz

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
