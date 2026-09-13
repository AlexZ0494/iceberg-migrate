#!/bin/bash
set -e

export JAVA_HOME=/opt/java/openjdk
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop

case "$1" in
  namenode)
    if [ ! -d /opt/hadoop/data/nameNode/current ]; then
      echo "Formatting NameNode..."
      hdfs namenode -format -force
    fi
    hdfs namenode
    ;;
  datanode)
    hdfs datanode
    ;;
  resourcemanager)
    yarn resourcemanager
    ;;
  nodemanager)
    yarn nodemanager
    ;;
  *)
    exec "$@"
    ;;
esac
