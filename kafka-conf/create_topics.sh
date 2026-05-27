#!/bin/bash

KAFKA_HOME=/opt/kafka
TOPICS=(
    "maxwell"
    "ecommerce-events"
    "ecommerce-orders"
    "ods_user_info"
    "ods_order_info"
    "ods_order_detail"
)

echo "=== Creating Kafka topics ==="

for topic in "${TOPICS[@]}"; do
    echo "Creating topic: $topic"
    $KAFKA_HOME/bin/kafka-topics.sh --create \
        --topic $topic \
        --bootstrap-server localhost:9092 \
        --partitions 3 \
        --replication-factor 1 \
        --if-not-exists
done

echo "=== Listing all topics ==="
$KAFKA_HOME/bin/kafka-topics.sh --list --bootstrap-server localhost:9092