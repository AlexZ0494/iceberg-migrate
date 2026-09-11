#!/bin/bash
set -e

# Если передана команда — просто выполняем её (для одноразовых задач)
if [ "$1" = "--cmd" ]; then
    shift
    exec "$@"
fi

ROLE="${HADOOP_ROLE:-namenode}"

# Гарантируем, что SSH-ключи настроены (нужны для некоторых Hadoop-скриптов)
if [ ! -f /root/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
fi

case "$ROLE" in
    namenode)
        # Форматируем при первом запуске
        if [ ! -d /hadoop/dfs/name/current ]; then
            $HADOOP_HOME/bin/hdfs namenode -format -force -nonInteractive
        fi
        $HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR namenode
        ;;
    datanode)
        $HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR datanode
        ;;
    resourcemanager)
        $HADOOP_HOME/bin/yarn --config $HADOOP_CONF_DIR resourcemanager
        ;;
    nodemanager)
        $HADOOP_HOME/bin/yarn --config $HADOOP_CONF_DIR nodemanager
        ;;
    *)
        echo "Unknown HADOOP_ROLE: $ROLE"
        exit 1
        ;;
esac
