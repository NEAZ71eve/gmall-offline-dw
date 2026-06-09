#!/bin/bash

# ============================================================================
# 服务监控脚本 - 离线数仓版
# 监控 Hadoop、Hive、DolphinScheduler、DataX 等服务的运行状态
# 作者：电商数仓项目
# ============================================================================

# 加载告警脚本
ALERT_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALERT_SCRIPT="${ALERT_SCRIPT_DIR}/alert.sh"

LOG_DIR="/var/log/gmall"
MONITOR_INTERVAL=60  # 监控间隔（秒）

# 创建日志目录
mkdir -p "$LOG_DIR"

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
    echo ""
    echo "=========================================="
    echo "         Hadoop 集群监控"
    echo "=========================================="

    local hadoop_home=${HADOOP_HOME:-/opt/hadoop}

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
# 3. 检查 Hive
# ============================================================================
check_hive() {
    echo ""
    echo "=========================================="
    echo "         Hive 监控"
    echo "=========================================="

    local hive_home=${HIVE_HOME:-/opt/hive}

    # 检查 HiveServer2
    check_java_process "HiveServer2" "HiveServer2"

    # 检查 Metastore
    check_java_process "HiveMetaStore" "Hive Metastore"

    # 检查 Hive 数据库连接
    echo -n "检查 Hive Metastore 连接... "
    if timeout 10 $hive_home/bin/beeline -u "jdbc:hive2://localhost:10000" -e "SELECT 1" 2>/dev/null | grep -q "1"; then
        echo "[OK] Hive Metastore 连接正常"
    else
        echo "[WARN] 无法连接 Hive Metastore"
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
# 5. 检查 DolphinScheduler
# ============================================================================
check_dolphinscheduler() {
    echo ""
    echo "=========================================="
    echo "         DolphinScheduler 监控"
    echo "=========================================="

    local ds_home=${DOLPHINSCHEDULER_HOME:-/opt/dolphinscheduler}

    # 检查 Master Server
    check_java_process "DolphinSchedulerMaster" "DS Master"

    # 检查 Worker Server
    check_java_process "DolphinSchedulerWorker" "DS Worker"

    # 检查 API Server
    check_java_process "DolphinSchedulerApi" "DS API"

    # 检查 Alert Server
    check_java_process "DolphinSchedulerAlert" "DS Alert"

    # 检查 DolphinScheduler 服务端口
    echo -n "检查 DolphinScheduler Web UI... "
    local ds_port=${DS_PORT:-12345}
    if timeout 5 curl -s "http://localhost:$ds_port/dolphinscheduler/" > /dev/null 2>&1; then
        echo "[OK] DolphinScheduler Web UI 可访问"
    else
        echo "[WARN] DolphinScheduler Web UI 不可访问"
    fi

    # 检查今日工作流执行情况
    echo -n "检查工作流实例状态... "
    local workflow_count=$(curl -s -X GET "http://localhost:$ds_port/dolphinscheduler/projects" \
        -H "token: ${DS_TOKEN}" 2>/dev/null | grep -o '"total":[0-9]*' | grep -o '[0-9]*' || echo "0")
    echo "[INFO] 工作流总数: ${workflow_count}"
}

# ============================================================================
# 6. 检查 DataX
# ============================================================================
check_datax() {
    echo ""
    echo "=========================================="
    echo "         DataX 监控"
    echo "=========================================="

    local datax_home=${DATAX_HOME:-/opt/datax}

    # 检查 DataX 可执行文件
    echo -n "检查 DataX 可执行性... "
    if [ -x "$datax_home/bin/datax.py" ]; then
        echo "[OK] DataX 可执行"
    else
        echo "[WARN] DataX 不可执行"
    fi

    # 检查 DataX 任务日志
    echo -n "检查 DataX 任务日志... "
    local log_dir="$datax_home/log"
    if [ -d "$log_dir" ]; then
        local recent_logs=$(find "$log_dir" -name "*.log" -mtime -1 2>/dev/null | wc -l)
        echo "[INFO] 最近1天日志数: ${recent_logs}"
    else
        echo "[INFO] 无日志目录"
    fi
}

# ============================================================================
# 7. 检查 MySQL
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
        local connections=$(mysql -u root -ptestpass -h 127.0.0.1 -P 3306 -e "SHOW STATUS LIKE 'Threads_connected';" 2>/dev/null | awk 'NR>1 {print $2}')
        if [ ! -z "$connections" ]; then
            if [ "$connections" -gt 500 ]; then
                echo "[WARN] 连接数: ${connections}"
            else
                echo "[OK] 连接数: ${connections}"
            fi
        fi

        # 检查查询缓存命中率
        echo -n "检查查询缓存... "
        local qch=$(mysql -u root -ptestpass -h 127.0.0.1 -P 3306 -e "SHOW STATUS LIKE 'Qcache_hits';" 2>/dev/null | awk 'NR>1 {print $2}')
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
# 8. 检查 ETL 任务状态
# ============================================================================
check_etl_tasks() {
    echo ""
    echo "=========================================="
    echo "         ETL 任务状态监控"
    echo "=========================================="

    local ds_port=${DS_PORT:-12345}

    # 检查今日工作流执行情况
    echo -n "检查今日工作流实例... "
    local today=$(date +%Y-%m-%d)
    local instances=$(curl -s -X GET "http://localhost:$ds_port/dolphinscheduler/projects/gmall/workflow-instances?startDate=$today" \
        -H "token: ${DS_TOKEN}" 2>/dev/null | grep -o '"total":[0-9]*' | grep -o '[0-9]*' || echo "0")
    echo "[INFO] 今日工作流实例数: ${instances}"

    # 检查失败的 ETL 任务
    echo -n "检查失败的任务... "
    local failed_tasks=$(curl -s -X GET "http://localhost:$ds_port/dolphinscheduler/projects/gmall/workflow-instances?startDate=$today&state=FAILED" \
        -H "token: ${DS_TOKEN}" 2>/dev/null | grep -o '"total":[0-9]*' | grep -o '[0-9]*' || echo "0")
    if [ "$failed_tasks" -gt 0 ]; then
        echo "[ERROR] 失败任务数: ${failed_tasks}"
    else
        echo "[OK] 失败任务数: 0"
    fi

    # 检查数据同步任务
    echo -n "检查数据同步任务... "
    local sync_count=$(curl -s -X GET "http://localhost:$ds_port/dolphinscheduler/projects/gmall/task-instances?startDate=$today&taskName=DataX" \
        -H "token: ${DS_TOKEN}" 2>/dev/null | grep -o '"total":[0-9]*' | grep -o '[0-9]*' || echo "0")
    echo "[INFO] 数据同步任务数: ${sync_count}"
}

# ============================================================================
# 9. 检查系统资源
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

    # 负载
    echo -n "系统负载... "
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    echo "[INFO] 1分钟负载: $load"

    # YARN 资源
    echo -n "检查 YARN 资源... "
    local yarn_home=${HADOOP_HOME:-/opt/hadoop}
    local available_memory=$(timeout 5 $yarn_home/bin/yarn node -list 2>/dev/null | grep -E "GB" | awk '{sum += $5} END {print sum}' || echo "0")
    echo "[INFO] YARN 可用内存: ${available_memory}GB"
}

# ============================================================================
# 10. 检查数据新鲜度
# ============================================================================
check_data_freshness() {
    echo ""
    echo "=========================================="
    echo "         数据新鲜度监控"
    echo "=========================================="

    local hive_home=${HIVE_HOME:-/opt/hive}
    local today=$(date +%Y-%m-%d)
    local yesterday=$(date -d "yesterday" +%Y-%m-%d)

    # 检查 ODS 层最新分区
    echo -n "检查 ODS 层最新分区... "
    local ods_partition=$(timeout 30 $hive_home/bin/hive -e "SHOW PARTITIONS gmall_ods.ods_user_info" 2>/dev/null | tail -1 | grep -o "dt=[0-9-]*" | cut -d= -f2)
    if [ ! -z "$ods_partition" ]; then
        if [ "$ods_partition" == "$yesterday" ] || [ "$ods_partition" == "$today" ]; then
            echo "[OK] ODS 最新分区: $ods_partition"
        else
            echo "[WARN] ODS 最新分区: $ods_partition (预期: $yesterday 或 $today)"
        fi
    else
        echo "[WARN] 无法获取 ODS 分区信息"
    fi

    # 检查 DWD 层最新分区
    echo -n "检查 DWD 层最新分区... "
    local dwd_partition=$(timeout 30 $hive_home/bin/hive -e "SHOW PARTITIONS gmall_dwd.dwd_order_info" 2>/dev/null | tail -1 | grep -o "dt=[0-9-]*" | cut -d= -f2)
    if [ ! -z "$dwd_partition" ]; then
        if [ "$dwd_partition" == "$yesterday" ] || [ "$dwd_partition" == "$today" ]; then
            echo "[OK] DWD 最新分区: $dwd_partition"
        else
            echo "[WARN] DWD 最新分区: $dwd_partition (预期: $yesterday 或 $today)"
        fi
    else
        echo "[WARN] 无法获取 DWD 分区信息"
    fi

    # 检查 ADS 层数据
    echo -n "检查 ADS 层数据... "
    local ads_count=$(timeout 30 $hive_home/bin/hive -e "SELECT COUNT(*) FROM gmall_ads.ads_gmv_day WHERE dt='$yesterday'" 2>/dev/null | tail -1)
    if [ ! -z "$ads_count" ] && [ "$ads_count" -gt 0 ]; then
        echo "[OK] ADS 昨日报表已生成"
    else
        echo "[WARN] ADS 昨日报表未生成或数据为空"
    fi
}

# ============================================================================
# 11. 生成监控报告
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
        check_hive
        check_dolphinscheduler
        check_datax
        check_mysql
        check_etl_tasks
        check_system_resources
        check_data_freshness

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
        hive)
            check_hive
            ;;
        dolphinscheduler)
            check_dolphinscheduler
            ;;
        datax)
            check_datax
            ;;
        mysql)
            check_mysql
            ;;
        etl)
            check_etl_tasks
            ;;
        freshness)
            check_data_freshness
            ;;
        resources)
            check_system_resources
            ;;
        all)
            generate_report
            ;;
        *)
            echo "用法: $0 {hadoop|hive|dolphinscheduler|datax|mysql|etl|freshness|resources|all}"
            echo "  hadoop          - 检查 Hadoop 集群"
            echo "  hive            - 检查 Hive"
            echo "  dolphinscheduler - 检查 DolphinScheduler"
            echo "  datax           - 检查 DataX"
            echo "  mysql           - 检查 MySQL"
            echo "  etl             - 检查 ETL 任务状态"
            echo "  freshness       - 检查数据新鲜度"
            echo "  resources       - 检查系统资源"
            echo "  all             - 检查所有服务（默认）"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
