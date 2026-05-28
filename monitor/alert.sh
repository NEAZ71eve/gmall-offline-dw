#!/bin/bash

# ============================================================================
# 告警脚本
# 支持邮件、钉钉、企业微信告警
# 作者：电商数仓项目
# ============================================================================

# 告警配置
DINGTALK_WEBHOOK=""  # 钉钉机器人webhook地址
EMAIL_SMTP_HOST="smtp.example.com"
EMAIL_SMTP_PORT=25
EMAIL_FROM="alarm@example.com"
EMAIL_TO="admin@example.com"

# 告警级别
LEVEL_INFO="INFO"
LEVEL_WARN="WARN"
LEVEL_ERROR="ERROR"
LEVEL_CRITICAL="CRITICAL"

# 告警函数：发送钉钉消息
send_dingtalk() {
    local title=$1
    local content=$2
    local level=$3

    if [ -z "$DINGTALK_WEBHOOK" ]; then
        echo "[INFO] 钉钉webhook未配置，跳过告警"
        return 0
    fi

    local timestamp=$(date +%s%3N)
    local sign=$(echo -n "token=$DINGTALK_WEBHOOK&timestamp=$timestamp" | openssl dgst -sha256 -hmac "" -binary | base64)

    curl -s "https://oapi.dingtalk.com/robot/send?access_token=&timestamp=$timestamp&sign=$sign" \
        -H "Content-Type: application/json" \
        -d "{
            \"msgtype\": \"markdown\",
            \"markdown\": {
                \"title\": \"[$level] $title\",
                \"text\": \"## [$level] $title\n\n$content\n\n---\n**时间**: $(date '+%Y-%m-%d %H:%M:%S')\n**环境**: ${ENV:-prod}\"
            }
        }"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 钉钉告警已发送: [$level] $title"
}

# 告警函数：发送邮件
send_email() {
    local subject=$1
    local content=$2
    local level=$3

    if [ -z "$EMAIL_SMTP_HOST" ]; then
        echo "[INFO] 邮件SMTP未配置，跳过告警"
        return 0
    fi

    echo -e "Subject: $subject\n\n$content" | sendmail -f "$EMAIL_FROM" "$EMAIL_TO"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 邮件告警已发送: $subject"
}

# 告警函数：记录日志
log_alarm() {
    local level=$1
    local title=$2
    local content=$3
    local log_file="/var/log/alarm.log"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $title: $content" >> "$log_file"

    # 如果是错误级别，同步发送告警
    if [ "$level" == "$LEVEL_ERROR" ] || [ "$level" == "$LEVEL_CRITICAL" ]; then
        send_dingtalk "$title" "$content" "$level"
        send_email "$title" "$content" "$level"
    fi
}

# ============================================================================
# 常用告警场景
# ============================================================================

# 1. 服务宕机告警
alarm_service_down() {
    local service_name=$1
    local hostname=$(hostname)

    log_alarm "$LEVEL_ERROR" "服务宕机告警" "
**服务名称**: $service_name
**主机**: $hostname
**状态**: 服务进程不存在
**建议**: 检查服务状态和日志文件
"
}

# 2. ETL任务失败告警
alarm_etl_failed() {
    local task_name=$1
    local error_msg=$2
    local log_file=$3

    log_alarm "$LEVEL_ERROR" "ETL任务失败告警" "
**任务名称**: $task_name
**错误信息**: $error_msg
**日志文件**: $log_file
**建议**: 检查数据源、数据质量和程序逻辑
"
}

# 3. 数据延迟告警
alarm_data_delay() {
    local table_name=$1
    local delay_hours=$2

    log_alarm "$LEVEL_WARN" "数据延迟告警" "
**表名**: $table_name
**延迟时间**: ${delay_hours}小时
**建议**: 检查ETL任务执行状态和数据源
"
}

# 4. 数据量异常告警
alarm_data_anomaly() {
    local table_name=$1
    local expected_count=$2
    local actual_count=$3

    local change_rate=$(awk "BEGIN {printf \"%.2f\", ($actual_count - $expected_count) / $expected_count * 100}")

    log_alarm "$LEVEL_WARN" "数据量异常告警" "
**表名**: $table_name
**预期数据量**: $expected_count
**实际数据量**: $actual_count
**变化率**: ${change_rate}%
**建议**: 检查数据源是否有异常变化
"
}

# 5. 磁盘空间不足告警
alarm_disk_full() {
    local disk_path=$1
    local usage_percent=$2

    log_alarm "$LEVEL_CRITICAL" "磁盘空间不足告警" "
**路径**: $disk_path
**使用率**: ${usage_percent}%
**建议**: 及时清理日志或扩展磁盘空间
"
}

# 6. 内存使用率过高告警
alarm_memory_high() {
    local usage_percent=$1
    local threshold=80

    log_alarm "$LEVEL_WARN" "内存使用率过高告警" "
**使用率**: ${usage_percent}%
**阈值**: ${threshold}%
**建议**: 检查是否有内存泄漏，增加内存或优化程序
"
}

# ============================================================================
# 主函数：测试告警
# ============================================================================
test_alarm() {
    echo "========================================"
    echo "         告警脚本测试"
    echo "========================================"

    echo ""
    echo "[1] 测试错误级别告警"
    log_alarm "$LEVEL_ERROR" "测试告警" "这是一条测试告警消息"

    echo ""
    echo "[2] 测试警告级别告警"
    log_alarm "$LEVEL_WARN" "测试警告" "这是一条测试警告消息"

    echo ""
    echo "[3] 测试服务宕机告警"
    alarm_service_down "Kafka"

    echo ""
    echo "[4] 测试ETL任务失败告警"
    alarm_etl_failed "ods_to_dwd" "Hive query failed" "/tmp/hive.log"

    echo ""
    echo "[5] 测试数据延迟告警"
    alarm_data_delay "dwd_order_info" 5

    echo ""
    echo "[6] 测试数据量异常告警"
    alarm_data_anomaly "dwd_order_detail" 1000 500

    echo ""
    echo "[7] 测试磁盘空间告警"
    alarm_disk_full "/hdfs" 90

    echo ""
    echo "[8] 测试内存告警"
    alarm_memory_high 85

    echo ""
    echo "========================================"
    echo "         告警测试完成"
    echo "========================================"
}

# 执行主函数或导出函数
if [ "$0" == "${BASH_SOURCE[0]}" ]; then
    test_alarm
else
    export -f send_dingtalk
    export -f send_email
    export -f log_alarm
    export -f alarm_service_down
    export -f alarm_etl_failed
    export -f alarm_data_delay
    export -f alarm_data_anomaly
    export -f alarm_disk_full
    export -f alarm_memory_high
fi
