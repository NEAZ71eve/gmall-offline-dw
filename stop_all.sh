#!/bin/bash

echo "================================================================================"
echo "                          停止所有服务"
echo "================================================================================"
echo ""

# 1. 停止 Flume
echo "[1/6] 停止 Flume..."
pkill -f flume-ng
sleep 2
echo "Flume 已停止"

# 2. 停止 Kafka
echo ""
echo "[2/6] 停止 Kafka..."
if [ -f /tmp/kafka.pid ]; then
    KAFKA_PID=$(cat /tmp/kafka.pid)
    kill $KAFKA_PID 2>/dev/null
    rm -f /tmp/kafka.pid
fi
pkill -f kafka.Kafka
sleep 2
echo "Kafka 已停止"

# 3. 停止 Maxwell
echo ""
echo "[3/6] 停止 Maxwell..."
pkill -f maxwell
sleep 2
echo "Maxwell 已停止"

# 4. 停止 Zookeeper
echo ""
echo "[4/6] 停止 Zookeeper..."
if [ -f /tmp/zookeeper.pid ]; then
    ZOOKEEPER_PID=$(cat /tmp/zookeeper.pid)
    kill $ZOOKEEPER_PID 2>/dev/null
    rm -f /tmp/zookeeper.pid
fi
pkill -f QuorumPeerMain
sleep 2
echo "Zookeeper 已停止"

# 5. 停止 Hadoop
echo ""
echo "[5/6] 停止 Hadoop..."
export HADOOP_HOME=/usr/local/hadoop
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

$HADOOP_HOME/bin/stop-all.sh 2>/dev/null
sleep 2
echo "Hadoop 已停止"

# 6. 停止 MySQL
echo ""
echo "[6/6] 停止 MySQL..."
if netstat -ano | Select-String ":3307"; then
    mysqladmin -h 127.0.0.1 -P 3307 shutdown 2>/dev/null
fi
pkill -f mysqld
sleep 2
echo "MySQL 已停止"

echo ""
echo "================================================================================"
echo "                          所有服务已停止"
echo "================================================================================"
echo ""

# 显示服务状态
echo "服务状态检查："
jps | grep -E 'NameNode|DataNode|QuorumPeerMain|Kafka' || echo "所有 Java 服务已停止"
