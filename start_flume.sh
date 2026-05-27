#!/bin/bash

FLUME_HOME=/opt/flume
CONF_DIR=/mnt/d/s/作业/flume-conf

echo "=== Starting Flume Agent ==="

# 启动 Flume 采集 Kafka 数据到 HDFS
nohup $FLUME_HOME/bin/flume-ng agent \
    -n a1 \
    -c $FLUME_HOME/conf \
    -f $CONF_DIR/kafka_to_hdfs.conf \
    -Dflume.root.logger=INFO,console > /tmp/flume.log 2>&1 &

sleep 5

echo "Flume agent started"
echo "Logs: /tmp/flume.log"