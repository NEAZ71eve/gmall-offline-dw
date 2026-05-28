#!/bin/bash

# ============================================================================
# 服务监控脚本
# 监控 Hadoop、Kafka、Flume、Hive 等服务的运行状态
# 作者：电商数仓项目
# ============================================================================

# 监控配置
ALERT_SCRIPT="/mnt/d/s/作业/monitor/alert.sh"
LOG_DIR="/var/log/gmall"
MONITOR_INTERVAL=60  # 监控间隔（秒）

# 创建日志目录
mkdir -p $LOG_DIR

# ============================================================================
# 1. 检查 Java 进程状态
# ============================================================================
check_java_process() {
    local process_name=$1
    local display_name=$2

    echo -n "检查 $display_name... "

    if pgrep -f "$process_name" > /dev/null; then
        local pid=$(pgrep -f "$process_name")
        local mem=$(ps -p $pid -o %mem --no-headers 2>/dev/null || echo "0")
        local cpu=$(ps -p $pid -o %cpu --no-headers 2>/dev/null || echo "0")

        echo "[OK] 运行中 (PID: $pid, CPU: ${cpu}%, MEM: ${mem}%)"
        return 0
    else
        echo "[ERROR] 未运行"
        # 发送告警
        if [ -f "$ALERT_SCRIPT" ]; then
            source "$ALERT_SCRIPT"
            alarm_service_down "$display_name"
        fi
        return 1
    fi
}

# ============================================================================
# 2. 检查 Hadoop 集群
# ============================================================================
check_hadoop() {
    echo "=========================================="
    echo "         Hadoop 集群监控"
    echo "=========================================="

    local hadoop_home=${HADOOP_HOME:-/usr/local/hadoop}

    # 检查 NameNode
    if check_java_process "NameNode" "NameNode"; then
        # 检查 HDFS 状态
        echo -n "检查 HDFS 健康状态... "
        local healthy=$(timeout 5 $hadoop_home/bin/hdfs dfsadmin -safemode get 2>/dev/null | grep -c "OFF")
        if [ "$healthy" -gt 0 ]; then
            echo "[OK] HDFS 正常（安全模式已关闭）"
        else
            echo "[WARN] HDFS 处于安全模式"
        fi
    fi

    # 检查 DataNode
    check_java_process "DataNode" "DataNode"

    # 检查 ResourceManager
    check_java_process "ResourceManager" "ResourceManager"

    # 检查 NodeManager
    check_java_process "NodeManager" "NodeManager"

    # 检查 HDFS 存储使用率
    echo -n "检查 HDFS 存储使用率... "
    local usage=$(timeout 5 $hadoop_home/bin/hdfs dfsadmin -report 2>/dev/null | grep "DFS Used%" | awk '{print $3}' | sed 's/%//')
    if [ ! -z "$usage" ]; then
        if [ "$usage" -gt 90 ]; then
            echo "[ERROR] HDFS 使用率 ${usage}% 超过阈值 90%"
        elif [ "$usage" -gt 80 ]; then
            echo "[WARN] HDFS 使用率 ${usage}% 超过阈值 80%"
        else
            echo "[OK] HDFS 使用率 ${usage}%"
        fi
    else
        echo "[ERROR] 无法获取 HDFS 状态"
    fi
}

# ============================================================================
# 3. 检查 Kafka
# ============================================================================
check_kafka() {
    echo ""
    echo "=========================================="
    echo "         Kafka 监控"
    echo "=========================================="

    local kafka_home=${KAFKA_HOME:-/opt/kafka}
    local kafka_topics=${kafka_home}/bin/kafka-topics.sh

    # 检查 Kafka 进程
    if check_java_process "kafka.Kafka" "Kafka Broker"; then
        # 检查 Kafka topic 列表
        echo -n "检查 Kafka topics... "
        local topic_count=$($kafka_topics --list --bootstrap-server localhost:9092 2>/dev/null | wc -l)
        echo "[OK] 共 ${topic_count} 个 topics"

        # 检查消费 lag
        echo -n "检查消费者 lag... "
        local lag=$(timeout 5 $kafka_home/bin/kafka-consumer-groups.sh \
            --bootstrap-server localhost:9092 \
            --all-groups \
            --describe 2>/dev/null | \
            awk '{sum+=$10} END {print sum+0}')

        if [ "$lag" -gt 10000 ]; then
            echo "[WARN] 消费 lag: ${lag}"
        else
            echo "[OK] 消费 lag: ${lag}"
        fi
    fi
}

# ============================================================================
# 4. 检查 Zookeeper
# ============================================================================
check_zookeeper() {
    echo ""
    echo "=========================================="
    echo "         Zookeeper 监控"
    echo "=========================================="

    check_java_process "QuorumPeerMain" "Zookeeper"
}

# ============================================================================
# 5. 检查 Flume
# ============================================================================
 check_flume() {
    echo ""
    echo "=========================================="
    echo "         Flume 监控"
    echo "=========================================="

    check_java_process "org.apache.flume.node.Application" "Flume Agent"
}

# ============================================================================
# 6. 检查 MySQL
# ============================================================================
check_mysql() {
    echo ""
    echo "=========================================="
    echo "         MySQL 监控"
    echo "=========================================="

    # 检查 MySQL 进程
    echo -n "检查 MySQL 进程... "
    if pgrep -f "mysqld" > /dev/null; then
        local pid=$(pgrep -f "mysqld")
        echo "[OK] 运行中 (PID: $pid)"

        # 检查连接数
        echo -n "检查数据库连接数... "
        local connections=$(mysql -u testuser -ptestpass -h 127.0.0.1 -P 3307 -e "SHOW STATUS LIKE 'Threads_connected';" 2>/dev/null | awk 'NR>1 {print $2}')
        if [ ! -z "$connections" ]; then
            if [ "$connections" -gt 500 ]; then
                echo "[WARN] 连接数: ${connections}"
            else
                echo "[OK] 连接数: ${connections}"
            fi
        fi

        # 检查查询缓存命中率
        echo -n "检查查询缓存... "
        local qch=$(mysql -u testuser -ptestpass -h 127.0.0.1 -P 3307 -e "SHOW STATUS LIKE 'Qcache_hits';" 2>/dev/null | awk 'NR>1 {print $2}')
        echo "[INFO] 查询缓存命中: ${qch:-0}"

    else
        echo "[ERROR] 未运行"
        if [ -f "$ALERT_SCRIPT" ]; then
            source "$ALERT_SCRIPT"
            alarm_service_down "MySQL"
        fi
    fi
}

# ============================================================================
# 7. 检查系统资源
# ============================================================================
check_system_resources() {
    echo ""
    echo "=========================================="
    echo "         系统资源监控"
    echo "=========================================="

    # CPU 使用率
    echo -n "CPU 使用率... "
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    local cpu_int=${cpu_usage%.*}
    if [ "$cpu_int" -gt 90 ]; then
        echo "[ERROR] CPU 使用率: ${cpu_usage}%"
    elif [ "$cpu_int" -gt 80 ]; then
        echo "[WARN] CPU 使用率: ${cpu_usage}%"
    else
        echo "[OK] CPU 使用率: ${cpu_usage}%"
    fi

    # 内存使用率
    echo -n "内存使用率... "
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
    if [ "$mem_usage" -gt 90 ]; then
        echo "[ERROR] 内存使用率: ${mem_usage}%"
    elif [ "$mem_usage" -gt 80 ]; then
        echo "[WARN] 内存使用率: ${mem_usage}%"
    else
        echo "[OK] 内存使用率: ${mem_usage}%"
    fi

    # 磁盘使用率
    echo -n "磁盘 / 使用率... "
    local disk_usage=$(df -h / | awk 'NR>1 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        echo "[ERROR] 磁盘使用率: ${disk_usage}%"
    elif [ "$disk_usage" -gt 80 ]; then
        echo "[WARN] 磁盘使用率: ${disk_usage}%"
    else
        echo "[OK] 磁盘使用率: ${disk_usage}%"
    fi
}

# ============================================================================
# 8. 生成监控报告
# ============================================================================
generate_report() {
    local report_file="$LOG_DIR/monitor_report_$(date +%Y%m%d_%H%M%S).log"

    {
        echo "=========================================="
        echo "         数据仓库服务监控报告"
        echo "=========================================="
        echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "主机名: $(hostname)"
        echo "=========================================="

        check_hadoop
        check_zookeeper
        check_kafka
        check_flume
        check_mysql
        check_system_resources

        echo ""
        echo "=========================================="
        echo "              监控完成"
        echo "=========================================="
    } | tee "$report_file"

    echo ""
    echo "[INFO] 监控报告已保存到: $report_file"
}

# ============================================================================
# 主函数
# ============================================================================
main() {
    case "${1:-all}" in
        hadoop)
            check_hadoop
            ;;
        kafka)
            check_kafka
            ;;
        mysql)
            check_mysql
            ;;
        resources)
            check_system_resources
            ;;
        all)
            generate_report
            ;;
        *)
            echo "用法: $0 {hadoop|kafka|mysql|resources|all}"
            echo "  hadoop    - 检查 Hadoop 集群"
            echo "  kafka     - 检查 Kafka"
            echo "  mysql     - 检查 MySQL"
            echo "  resources - 检查系统资源"
            echo "  all       - 检查所有服务（默认）"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
