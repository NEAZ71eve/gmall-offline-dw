#!/bin/bash

echo "=== Starting Kafka Ecosystem ==="

# 1. 启动 ZooKeeper
echo "1. Starting ZooKeeper..."
nohup /opt/zookeeper/bin/zkServer.sh start > /tmp/zookeeper.log 2>&1 &
sleep 5
echo "ZooKeeper started"

# 2. 启动 Kafka
echo "2. Starting Kafka..."
nohup /opt/kafka/bin/kafka-server-start.sh /mnt/d/s/作业/kafka-conf/server.properties > /tmp/kafka.log 2>&1 &
sleep 10
echo "Kafka started"

# 3. 创建必要的 topics
echo "3. Creating Kafka topics..."
bash /mnt/d/s/作业/kafka-conf/create_topics.sh

# 4. 启动 Maxwell
echo "4. Starting Maxwell..."
nohup java -jar /opt/maxwell/maxwell-1.49.0.jar --config /mnt/d/s/作业/maxwell/config.properties > /tmp/maxwell.log 2>&1 &
sleep 5
echo "Maxwell started"

echo "=== Kafka ecosystem started successfully ==="

# 显示状态
echo ""
echo "Service Status:"
jps | grep -E 'QuorumPeerMain|Kafka'