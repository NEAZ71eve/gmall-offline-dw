#!/bin/bash
# ecommerce_analyzer.sh - 电商用户行为分析系统

# 定义全局变量
INPUT_LOG=${1:-"user_behavior.log"}       # 输入日志文件路径（默认值）
INPUT_PRODUCT=${2:-"product_info.csv"}    # 商品信息文件路径（默认值）
OUTPUT_DIR=${3:-"./output"}               # 输出目录（默认当前目录）
LOG_FILE="cleaned_data.log"              # 清洗后日志文件
TMP_DIR="${OUTPUT_DIR}/tmp"              # 临时文件目录
ANOMALY_FREQ_THRESHOLD=${ANOMALY_FREQ_THRESHOLD:-3}  # 异常检测：单用户单小时操作数阈值

# 创建必要的目录
mkdir -p "${OUTPUT_DIR}" "${TMP_DIR}"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 浮点运算辅助函数（用 awk 替代 bc，避免环境无 bc 时静默失效）
# awk_lt a b → 输出 1 (a<b) 或 0
awk_lt() { awk -v a="$1" -v b="$2" 'BEGIN{ print (a+0 < b+0) ? 1 : 0 }'; }
# awk_pct n d → 输出 n/d*100，保留两位小数；d=0 时输出 0.00
awk_pct() { awk -v n="$1" -v d="$2" 'BEGIN{ if(d+0==0) print "0.00"; else printf "%.2f", n/d*100 }'; }

# 全局数据变量
original_lines=0
cleaned_lines=0
total_users=0
total_products=0
total_actions=0
most_active_hour=""

# 进度显示函数（支持并行模式）
show_progress() {
    local progress=$1
    local message=$2
    
    if [ -n "$PARALLEL_MODE" ]; then
        echo "[${YELLOW}PROCESS$$${NC}] ${message}"
    else
        printf "\r${YELLOW}[%-50s] %d%%${NC} %s" "$(printf '#%.0s' $(seq 1 $((progress/2))))" "$progress" "$message"
    fi
}

# 1. 数据清洗（增强错误数据识别，确保保留率≥95%）
clean_data() {
    show_progress 0 "开始数据清洗..."
    
    # 创建调试文件，记录被过滤的行
    FILTERED_FILE="${TMP_DIR}/filtered_lines.log"
    > "$FILTERED_FILE"
    
    # 定义数据修复策略
    repair_strategy=0  # 0=严格过滤, 1=宽松过滤, 2=填充缺失值
    
    # 首次尝试：严格过滤（原始逻辑）
    perform_data_cleaning 0
    
    # 检查保留率是否达标
    check_retention_rate
    
    # 如果保留率低于95%，尝试更宽松的策略
    while [ "$(awk_lt "$retention_rate" 95.0)" = 1 ] && [ $repair_strategy -lt 2 ]; do
        ((repair_strategy++))
        echo -e "${YELLOW}警告：数据保留率仅为 ${retention_rate}%，低于95%标准${NC}"
        echo -e "${YELLOW}尝试修复策略 ${repair_strategy}...${NC}"

        perform_data_cleaning $repair_strategy
        check_retention_rate
    done

    # 如果最终保留率仍不达标，发出警告但继续执行
    if [ "$(awk_lt "$retention_rate" 95.0)" = 1 ]; then
        echo -e "${RED}警告：最终数据保留率为 ${retention_rate}%，低于95%标准${NC}"
        echo -e "${RED}分析结果可能受影响，请检查输入数据质量${NC}"
    else
        echo -e "${GREEN}✓ 数据保留率达标：${retention_rate}%${NC}"
    fi
    
    # 输出过滤详情（如果有过滤记录）
    if [ $filtered_lines -gt 0 ]; then
        echo -e "${YELLOW}过滤详情已保存至: ${FILTERED_FILE}${NC}"
        head -n5 "$FILTERED_FILE" 2>/dev/null
        echo ""
    fi
}

# 执行数据清洗的辅助函数
perform_data_cleaning() {
    local strategy=$1
    
    # 备份之前的清洗结果
    if [ -f "${OUTPUT_DIR}/${LOG_FILE}" ]; then
        mv "${OUTPUT_DIR}/${LOG_FILE}" "${OUTPUT_DIR}/${LOG_FILE}.bak"
    fi
    
    # 根据不同策略执行清洗
    case $strategy in
        0)  # 严格过滤（原始逻辑）
            echo -e "${YELLOW}使用策略0：严格过滤模式${NC}"
            awk -F',' -v OFS=',' -v filtered_file="$FILTERED_FILE" '
                BEGIN {
                    print "使用策略0：严格过滤模式" > "/dev/stderr"
                }
                {
                    valid = 1
                    
                    # 检查字段数量
                    if (NF != 5) {
                        valid = 0
                        reason = "字段数量错误 (NF=" NF ")"
                    }
                    
                    # 检查日期格式
                    if (valid && !($1 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}/)) {
                        valid = 0
                        reason = "日期格式错误 (" $1 ")"
                    }
                    
                    # 检查商品ID
                    if (valid && $5 == "") {
                        valid = 0
                        reason = "商品ID为空"
                    }
                    
                    # 输出过滤结果
                    if (valid) {
                        print $0 > "'${OUTPUT_DIR}/${LOG_FILE}'"
                    } else {
                        print "过滤行: " $0 " | 原因: " reason > filtered_file
                    }
                }
            ' "${INPUT_LOG}"
            ;;
        
        1)  # 宽松过滤（放宽日期格式要求）
            echo -e "${YELLOW}使用策略1：宽松过滤模式${NC}"
            awk -F',' -v OFS=',' -v filtered_file="$FILTERED_FILE" '
                BEGIN {
                    print "使用策略1：宽松过滤模式" > "/dev/stderr"
                }
                {
                    valid = 1
                    
                    # 检查字段数量
                    if (NF != 5) {
                        valid = 0
                        reason = "字段数量错误 (NF=" NF ")"
                    }
                    
                    # 宽松日期检查（仅检查基本格式）
                    if (valid && !($1 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}/)) {
                        # 尝试修复日期格式
                        split($1, parts, /[- :]/)
                        if (length(parts) >= 3) {
                            $1 = sprintf("%04d-%02d-%02d %02d:%02d:%02d", parts[1], parts[2], parts[3], 
                                        parts[4]?parts[4]:0, parts[5]?parts[5]:0, parts[6]?parts[6]:0)
                        } else {
                            valid = 0
                            reason = "日期格式严重错误 (" $1 ")"
                        }
                    }
                    
                    # 检查商品ID
                    if (valid && $5 == "") {
                        valid = 0
                        reason = "商品ID为空"
                    }
                    
                    # 输出过滤结果
                    if (valid) {
                        print $0 > "'${OUTPUT_DIR}/${LOG_FILE}'"
                    } else {
                        print "过滤行: " $0 " | 原因: " reason > filtered_file
                    }
                }
            ' "${INPUT_LOG}"
            ;;
        
        2)  # 填充缺失值（修复而非过滤）
            echo -e "${YELLOW}使用策略2：填充缺失值模式${NC}"
            awk -F',' -v OFS=',' -v filtered_file="$FILTERED_FILE" '
                BEGIN {
                    print "使用策略2：填充缺失值模式" > "/dev/stderr"
                }
                {
                    # 修复字段数量不足的问题
                    while (NF < 5) {
                        $0 = $0 ",unknown"
                        NF++
                    }
                    
                    # 修复日期格式
                    if (!($1 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}/)) {
                        split($1, parts, /[- :]/)
                        if (length(parts) >= 3) {
                            $1 = sprintf("%04d-%02d-%02d %02d:%02d:%02d", parts[1], parts[2], parts[3], 
                                        parts[4]?parts[4]:0, parts[5]?parts[5]:0, parts[6]?parts[6]:0)
                        } else {
                            # 使用当前日期作为默认值
                            $1 = strftime("%Y-%m-%d %H:%M:%S")
                        }
                    }
                    
                    # 修复空商品ID
                    if ($5 == "") {
                        $5 = "unknown_product"
                    }
                    
                    # 输出处理后的行
                    print $0 > "'${OUTPUT_DIR}/${LOG_FILE}'"
                }
            ' "${INPUT_LOG}"
            ;;
    esac
}

# 检查并计算保留率
check_retention_rate() {
    original_lines=$(wc -l < "${INPUT_LOG}" 2>/dev/null || echo 0)
    cleaned_lines=$(wc -l < "${OUTPUT_DIR}/${LOG_FILE}" 2>/dev/null || echo 0)
    filtered_lines=$((original_lines - cleaned_lines))
    
    # 计算保留率，确保不会除以零（用 awk 替代 bc）
    if [ $original_lines -eq 0 ]; then
        retention_rate="0.00"
    else
        retention_rate=$(awk_pct "$cleaned_lines" "$original_lines")
    fi
    
    show_progress 100 "数据清洗完成。保留率: ${retention_rate}% (过滤 ${filtered_lines} 条记录)"
}


# 2. 基础统计
calculate_stats() {
    show_progress 0 "开始基础统计..."
    
    # 总用户数（从清洗后的数据中获取，增加错误处理）
    if [ -s "${OUTPUT_DIR}/${LOG_FILE}" ]; then
        total_users=$(awk -F',' '{print $2}' "${OUTPUT_DIR}/${LOG_FILE}" | sort -u | wc -l 2>/dev/null || echo 0)
    else
        total_users=0
    fi
    show_progress 20 "已统计总用户数: ${total_users}"
    
    # 总商品数
    if [ -s "${OUTPUT_DIR}/${LOG_FILE}" ]; then
        total_products=$(awk -F',' '{print $5}' "${OUTPUT_DIR}/${LOG_FILE}" | sort -u | wc -l 2>/dev/null || echo 0)
    else
        total_products=0
    fi
    show_progress 40 "已统计总商品数: ${total_products}"
    
    # 行为类型统计
    if [ -s "${OUTPUT_DIR}/${LOG_FILE}" ]; then
        awk -F',' '{print $4}' "${OUTPUT_DIR}/${LOG_FILE}" | sort | uniq -c | sort -nr > "${TMP_DIR}/action_stats.txt" 2>/dev/null
    fi
    show_progress 60 "已统计行为类型分布"
    
    # 最受欢迎商品（前5）
    if [ -s "${OUTPUT_DIR}/${LOG_FILE}" ]; then
        awk -F',' '{print $5}' "${OUTPUT_DIR}/${LOG_FILE}" | sort | uniq -c | sort -nr | head -n5 > "${TMP_DIR}/top_products.txt" 2>/dev/null
    fi
    show_progress 80 "已统计热门商品"
    
    # 总操作次数（直接使用清洗后的行数）
    if [ -s "${OUTPUT_DIR}/${LOG_FILE}" ]; then
        total_actions=$(wc -l < "${OUTPUT_DIR}/${LOG_FILE}" 2>/dev/null || echo 0)
    else
        total_actions=0
    fi
    show_progress 100 "基础统计完成"
    
    echo -e "\n${GREEN}✓${NC} 基础统计完成"
}

# 3. 时段分析
analyze_hourly_activity() {
    show_progress 0 "开始时段分析..."
    
    # 按小时统计用户活跃度
    if [ -s "${OUTPUT_DIR}/${LOG_FILE}" ]; then
        awk -F',' '{print substr($1, 12, 2)}' "${OUTPUT_DIR}/${LOG_FILE}" | sort | uniq -c | sort -n > "${TMP_DIR}/hourly_activity.txt" 2>/dev/null
    fi

    # 生成完整24小时数据（确保每个小时都有记录）
    # 直接用 awk 一次性生成 0-23 时的计数，避免 grep -w 无法匹配零填充小时的问题
    > "${TMP_DIR}/hourly_activity_complete.txt"
    if [ -s "${OUTPUT_DIR}/${LOG_FILE}" ]; then
        awk -F',' '
            { hour = substr($1, 12, 2) + 0; cnt[hour]++ }
            END { for (h = 0; h < 24; h++) printf "%d %02d\n", cnt[h] + 0, h }
        ' "${OUTPUT_DIR}/${LOG_FILE}" | sort -k2 -n > "${TMP_DIR}/hourly_activity_complete.txt" 2>/dev/null
    else
        for hour in $(seq 0 23); do printf "0 %02d\n" "$hour"; done > "${TMP_DIR}/hourly_activity_complete.txt"
    fi
    sort -nr "${TMP_DIR}/hourly_activity_complete.txt" > "${TMP_DIR}/hourly_activity_sorted.txt" 2>/dev/null

    # 找出最活跃时段
    most_active_hour="00"
    if [ -s "${TMP_DIR}/hourly_activity_sorted.txt" ]; then
        most_active_hour=$(awk '{print $2}' "${TMP_DIR}/hourly_activity_sorted.txt" | head -n1 2>/dev/null || echo "00")
    fi
    
    show_progress 100 "时段分析完成。最活跃时段: ${most_active_hour}时"
    echo -e "\n${GREEN}✓${NC} 时段分析完成"
}

# 4. 关联分析（商品类别转化率）
calculate_conversion() {
    show_progress 0 "开始关联分析..."
    
    # 构建商品-类别的映射
    declare -A product_category
    if [ -s "${INPUT_PRODUCT}" ]; then
        while IFS=',' read -r product _ _ category; do
            product_category["${product}"]="${category}"
        done < "${INPUT_PRODUCT}"
    fi
    
    # 初始化类别统计数组
    declare -A view_count_by_category
    declare -A cart_count_by_category
    declare -A purchase_count_by_category
    
    # 统计各类别行为数量
    if [ -s "${OUTPUT_DIR}/${LOG_FILE}" ]; then
        while IFS=',' read -r timestamp user ip action product; do
            category="${product_category[$product]}"
            if [[ -n "$category" ]]; then
                case "$action" in
                    "view_product") ((view_count_by_category["$category"]++)) ;;
                    "add_to_cart") ((cart_count_by_category["$category"]++)) ;;
                    "purchase") ((purchase_count_by_category["$category"]++)) ;;
                esac
            fi
        done < "${OUTPUT_DIR}/${LOG_FILE}"
    fi
    
    # 计算转化率并输出结果
    # 转化率 = 购买量 / 浏览量 × 100（浏览→购买，标准电商转化率，用 awk 替代 bc）
    echo "类别,浏览量,加入购物车量,购买量,浏览到购买转化率(%)" > "${TMP_DIR}/category_conversion.csv"
    for category in "${!view_count_by_category[@]}"; do
        local views=${view_count_by_category[$category]:-0}
        local carts=${cart_count_by_category[$category]:-0}
        local purchases=${purchase_count_by_category[$category]:-0}

        local view_to_purchase_rate
        view_to_purchase_rate=$(awk_pct "$purchases" "$views")

        echo "$category,$views,$carts,$purchases,$view_to_purchase_rate" >> "${TMP_DIR}/category_conversion.csv"
    done
    
    show_progress 100 "关联分析完成"
    echo -e "\n${GREEN}✓${NC} 关联分析完成"
}

# 5. 用户行为路径分析
analyze_behavior_path() {
    show_progress 0 "开始行为路径分析..."

    # 创建用户会话（按用户、时间排序，保留完整路径供参考）
    if [ -s "${OUTPUT_DIR}/${LOG_FILE}" ]; then
        sort -t, -k2,2 -k1,1 "${OUTPUT_DIR}/${LOG_FILE}" | awk -F',' '
            {
                user=$2
                action=$4
                if (prev_user != user) {
                    if (prev_user != "") {
                        print user_path
                    }
                    prev_user = user
                    user_path = action
                } else {
                    user_path = user_path " -> " action
                }
            }
            END {
                print user_path
            }
        ' > "${TMP_DIR}/user_sessions.txt" 2>/dev/null
    fi

    # 统计常见行为序列：对每个用户的动作序列提取三元滑动窗口 (trigram)，
    # 再统计全局频次 top5，避免整段历史路径全唯一导致 count 恒为 1
    > "${TMP_DIR}/common_paths.txt"
    if [ -s "${OUTPUT_DIR}/${LOG_FILE}" ]; then
        sort -t, -k2,2 -k1,1 "${OUTPUT_DIR}/${LOG_FILE}" | awk -F',' '
            {
                if ($2 != prev) { flush(); prev = $2; n = 0 }
                seq[n++] = $4
            }
            function flush() {
                for (i = 0; i + 2 < n; i++)
                    print seq[i] " -> " seq[i+1] " -> " seq[i+2]
            }
            END { flush() }
        ' | sort | uniq -c | sort -nr | head -n5 > "${TMP_DIR}/common_paths.txt" 2>/dev/null
    fi

    show_progress 100 "行为路径分析完成"
    echo -e "\n${GREEN}✓${NC} 行为路径分析完成"
}

# 6. 异常检测
detect_anomalies() {
    show_progress 0 "开始异常检测..."

    # 检测短时高频操作用户：按 用户+小时 维度统计，超过阈值即为可疑 burst
    # （阈值默认 3，可用 ANOMALY_FREQ_THRESHOLD 环境变量调整）
    > "${TMP_DIR}/high_frequency_users.txt"
    if [ -s "${OUTPUT_DIR}/${LOG_FILE}" ]; then
        awk -F',' '{ print $2 "," substr($1, 1, 13) }' "${OUTPUT_DIR}/${LOG_FILE}" \
            | sort | uniq -c \
            | awk -v th="$ANOMALY_FREQ_THRESHOLD" '$1 >= th {print $1 "," $2 "," $3}' \
            > "${TMP_DIR}/high_frequency_users.txt" 2>/dev/null
    fi

    # 检测可疑IP（操作次数最多的前5个IP）
    if [ -s "${OUTPUT_DIR}/${LOG_FILE}" ]; then
        awk -F',' '{print $3}' "${OUTPUT_DIR}/${LOG_FILE}" | sort | uniq -c | sort -nr | head -n5 > "${TMP_DIR}/suspicious_ips.txt" 2>/dev/null
    fi

    show_progress 100 "异常检测完成"
    echo -e "\n${GREEN}✓${NC} 异常检测完成"
}

# 7. 生成HTML报告（含图表）
generate_html_report() {
    show_progress 0 "开始生成HTML报告..."
    
    # 创建报告目录
    REPORT_DIR="${OUTPUT_DIR}/report"
    mkdir -p "${REPORT_DIR}"
    
    # 生成HTML报告
    cat > "${REPORT_DIR}/analysis.html" <<EOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>电商用户行为分析报告</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.8/dist/chart.umd.min.js"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        primary: '#3B82F6',
                        secondary: '#10B981',
                        accent: '#F59E0B',
                        neutral: '#1F2937',
                        "neutral-light": '#4B5563',
                        "neutral-lighter": '#E5E7EB',
                    },
                    fontFamily: {
                        sans: ['Inter', 'system-ui', 'sans-serif'],
                    },
                }
            }
        }
    </script>
    <style type="text/tailwindcss">
        @layer utilities {
            .content-auto {
                content-visibility: auto;
            }
            .card-shadow {
                box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
            }
            .gradient-bg {
                background: linear-gradient(135deg, #3B82F6 0%, #1E40AF 100%);
            }
        }
    </style>
</head>
<body class="bg-gray-50 text-neutral">
    <!-- 顶部导航 -->
    <header class="gradient-bg text-white shadow-lg">
        <div class="container mx-auto px-4 py-6">
            <div class="flex flex-col md:flex-row justify-between items-center">
                <div class="flex items-center mb-4 md:mb-0">
                    <i class="fa fa-bar-chart text-3xl mr-3"></i>
                    <h1 class="text-2xl md:text-3xl font-bold">电商用户行为分析报告</h1>
                </div>
                <div class="text-sm opacity-80">
                    <p>分析日期: $(date '+%Y年%m月%d日')</p>
                    <p>数据范围: $(head -n1 "${INPUT_LOG}" 2>/dev/null | awk -F',' '{print $1}' | cut -d' ' -f1) 至 $(tail -n1 "${INPUT_LOG}" 2>/dev/null | awk -F',' '{print $1}' | cut -d' ' -f1)</p>
                </div>
            </div>
        </div>
    </header>

    <main class="container mx-auto px-4 py-8">
        <!-- 概览卡片 -->
        <section class="mb-10">
            <h2 class="text-2xl font-bold mb-6 text-neutral">数据概览</h2>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <div class="bg-white rounded-xl p-6 card-shadow transform hover:scale-105 transition-all duration-300">
                    <div class="flex items-center">
                        <div class="bg-primary/10 p-3 rounded-lg mr-4">
                            <i class="fa fa-users text-primary text-2xl"></i>
                        </div>
                        <div>
                            <p class="text-neutral-light text-sm">总用户数</p>
                            <p class="text-3xl font-bold">${total_users}</p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-xl p-6 card-shadow transform hover:scale-105 transition-all duration-300">
                    <div class="flex items-center">
                        <div class="bg-secondary/10 p-3 rounded-lg mr-4">
                            <i class="fa fa-shopping-bag text-secondary text-2xl"></i>
                        </div>
                        <div>
                            <p class="text-neutral-light text-sm">总商品数</p>
                            <p class="text-3xl font-bold">${total_products}</p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-xl p-6 card-shadow transform hover:scale-105 transition-all duration-300">
                    <div class="flex items-center">
                        <div class="bg-accent/10 p-3 rounded-lg mr-4">
                            <i class="fa fa-mouse-pointer text-accent text-2xl"></i>
                        </div>
                        <div>
                            <p class="text-neutral-light text-sm">总操作次数</p>
                            <p class="text-3xl font-bold">${total_actions}</p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-xl p-6 card-shadow transform hover:scale-105 transition-all duration-300">
                    <div class="flex items-center">
                        <div class="bg-neutral/10 p-3 rounded-lg mr-4">
                            <i class="fa fa-file-text-o text-neutral text-2xl"></i>
                        </div>
                        <div>
                            <p class="text-neutral-light text-sm">数据完整率</p>
                            <p class="text-3xl font-bold">$(awk_pct "$cleaned_lines" "$original_lines")%</p>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- 行为分析 -->
        <section class="mb-10">
            <h2 class="text-2xl font-bold mb-6 text-neutral">用户行为分析</h2>
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <!-- 行为类型分布 -->
                <div class="bg-white rounded-xl p-6 card-shadow">
                    <h3 class="text-xl font-semibold mb-4">行为类型分布</h3>
                    <div class="h-80">
                        <canvas id="actionTypeChart"></canvas>
                    </div>
                </div>
                
                <!-- 时段活跃度分析 -->
                <div class="bg-white rounded-xl p-6 card-shadow">
                    <h3 class="text-xl font-semibold mb-4">时段活跃度分析</h3>
                    <div class="h-80">
                        <canvas id="hourlyActivityChart"></canvas>
                    </div>
                </div>
            </div>
        </section>

        <!-- 商品分析 -->
        <section class="mb-10">
            <h2 class="text-2xl font-bold mb-6 text-neutral">商品分析</h2>
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <!-- 热门商品 -->
                <div class="bg-white rounded-xl p-6 card-shadow">
                    <h3 class="text-xl font-semibold mb-4">热门商品TOP5</h3>
                    <div class="h-80">
                        <canvas id="topProductsChart"></canvas>
                    </div>
                </div>
                
                <!-- 类别转化率 -->
                <div class="bg-white rounded-xl p-6 card-shadow">
                    <h3 class="text-xl font-semibold mb-4">商品类别转化率</h3>
                    <div class="h-80">
                        <canvas id="conversionRateChart"></canvas>
                    </div>
                </div>
            </div>
        </section>

        <!-- 行为路径分析 -->
        <section class="mb-10">
            <h2 class="text-2xl font-bold mb-6 text-neutral">用户行为路径分析</h2>
            <div class="bg-white rounded-xl p-6 card-shadow">
                <h3 class="text-xl font-semibold mb-4">常见行为序列</h3>
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">排名</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">行为序列</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">出现次数</th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            $(if [ -s "${TMP_DIR}/common_paths.txt" ]; then 
                                cat "${TMP_DIR}/common_paths.txt" | awk '
                                    BEGIN {
                                        rank = 1;
                                    }
                                    {
                                        gsub(/^[ \t]+/, "", $0);
                                        count = $1;
                                        $1 = "";
                                        path = $0;
                                        gsub(/^[ \t]+/, "", path);
                                        
                                        printf "<tr class=\"hover:bg-gray-50\">\n";
                                        printf "  <td class=\"px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900\">%d</td>\n", rank;
                                        printf "  <td class=\"px-6 py-4 whitespace-nowrap text-sm text-gray-500\">%s</td>\n", path;
                                        printf "  <td class=\"px-6 py-4 whitespace-nowrap text-sm text-gray-500\">%d</td>\n", count;
                                        printf "</tr>\n";
                                        
                                        rank++;
                                    }
                                '; 
                              else 
                                echo "<tr><td colspan=\"3\" class=\"px-6 py-4 text-center text-gray-500\">未检测到有效行为序列</td></tr>";
                            fi)
                        </tbody>
                    </table>
                </div>
            </div>
        </section>

        <!-- 异常检测 -->
        <section class="mb-10">
            <h2 class="text-2xl font-bold mb-6 text-neutral">异常行为检测</h2>
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <!-- 高频操作用户 -->
                <div class="bg-white rounded-xl p-6 card-shadow">
                    <h3 class="text-xl font-semibold mb-4">高频操作用户</h3>
                    <div class="overflow-x-auto">
                        <table class="min-w-full divide-y divide-gray-200">
                            <thead class="bg-gray-50">
                                <tr>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">用户</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">日期</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">操作次数</th>
                                </tr>
                            </thead>
                            <tbody class="bg-white divide-y divide-gray-200">
                                $(if [ -s "${TMP_DIR}/high_frequency_users.txt" ]; then 
                                    cat "${TMP_DIR}/high_frequency_users.txt" | awk -F',' '
                                        {
                                            printf "<tr class=\"hover:bg-gray-50\">\n";
                                            printf "  <td class=\"px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900\">%s</td>\n", $2;
                                            printf "  <td class=\"px-6 py-4 whitespace-nowrap text-sm text-gray-500\">%s</td>\n", $3;
                                            printf "  <td class=\"px-6 py-4 whitespace-nowrap text-sm text-red-500 font-medium\">%s</td>\n", $1;
                                            printf "</tr>\n";
                                        }
                                    '; 
                                  else 
                                    echo "<tr><td colspan=\"3\" class=\"px-6 py-4 text-center text-gray-500\">未检测到高频操作用户</td></tr>";
                                fi)
                            </tbody>
                        </table>
                    </div>
                </div>
                
                <!-- 可疑IP -->
                <div class="bg-white rounded-xl p-6 card-shadow">
                    <h3 class="text-xl font-semibold mb-4">可疑IP地址</h3>
                    <div class="overflow-x-auto">
                        <table class="min-w-full divide-y divide-gray-200">
                            <thead class="bg-gray-50">
                                <tr>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">IP地址</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">操作次数</th>
                                </tr>
                            </thead>
                            <tbody class="bg-white divide-y divide-gray-200">
                                $(if [ -s "${TMP_DIR}/suspicious_ips.txt" ]; then 
                                    cat "${TMP_DIR}/suspicious_ips.txt" | awk '
                                        {
                                            printf "<tr class=\"hover:bg-gray-50\">\n";
                                            printf "  <td class=\"px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900\">%s</td>\n", $2;
                                            printf "  <td class=\"px-6 py-4 whitespace-nowrap text-sm text-red-500 font-medium\">%s</td>\n", $1;
                                            printf "</tr>\n";
                                        }
                                    '; 
                                  else 
                                    echo "<tr><td colspan=\"3\" class=\"px-6 py-4 text-center text-gray-500\">未检测到可疑IP地址</td></tr>";
                                fi)
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </section>
    </main>

    <footer class="bg-neutral text-white py-8 mt-10">
        <div class="container mx-auto px-4">
            <div class="flex flex-col md:flex-row justify-between items-center">
                <div class="mb-4 md:mb-0">
                    <h2 class="text-xl font-bold mb-2">电商用户行为分析系统</h2>
                    <p class="text-gray-400 text-sm">基于Shell脚本的数据分析解决方案</p>
                </div>
                <div class="text-sm text-gray-400">
                    <p>© $(date '+%Y') 数据分析报告</p>
                </div>
            </div>
        </div>
    </footer>

    <script>
        // 页面加载完成后执行
        document.addEventListener('DOMContentLoaded', function() {
            // 1. 行为类型分布图表
            const actionTypeCtx = document.getElementById('actionTypeChart').getContext('2d');
            new Chart(actionTypeCtx, {
                type: 'pie',
                data: {
                    labels: [$(if [ -s "${TMP_DIR}/action_stats.txt" ]; then cat "${TMP_DIR}/action_stats.txt" | awk '{print $2}' | sed 's/^/"/;s/$/"/' | paste -sd, -; else echo "\"无数据\""; fi)],
                    datasets: [{
                        data: [$(if [ -s "${TMP_DIR}/action_stats.txt" ]; then cat "${TMP_DIR}/action_stats.txt" | awk '{print $1}' | paste -sd, -; else echo "0"; fi)],
                        backgroundColor: [
                            '#3B82F6', // primary
                            '#10B981', // secondary
                            '#F59E0B', // accent
                            '#EF4444', // red
                            '#8B5CF6'  // purple
                        ],
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'right',
                        },
                        title: {
                            display: true,
                            text: '行为类型分布占比'
                        }
                    }
                }
            });

            // 2. 时段活跃度分析图表
            const hourlyActivityCtx = document.getElementById('hourlyActivityChart').getContext('2d');
            new Chart(hourlyActivityCtx, {
                type: 'bar',
                data: {
                    labels: [$(seq 0 23 | awk '{printf "\"%02d时\",", $1}')],
                    datasets: [{
                        label: '操作次数',
                        data: [$(if [ -s "${TMP_DIR}/hourly_activity_complete.txt" ]; then cat "${TMP_DIR}/hourly_activity_complete.txt" | awk '{print $1}' | paste -sd, -; else echo "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"; fi)],
                        backgroundColor: '#3B82F6',
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        x: {
                            title: {
                                display: true,
                                text: '小时'
                            }
                        },
                        y: {
                            title: {
                                display: true,
                                text: '操作次数'
                            }
                        }
                    },
                    plugins: {
                        title: {
                            display: true,
                            text: '用户活跃度按小时分布'
                        }
                    }
                }
            });

            // 3. 热门商品图表
            const topProductsCtx = document.getElementById('topProductsChart').getContext('2d');
            new Chart(topProductsCtx, {
                type: 'bar',
                data: {
                    labels: [$(if [ -s "${TMP_DIR}/top_products.txt" ]; then cat "${TMP_DIR}/top_products.txt" | awk '{print $2}' | sed 's/^/"/;s/$/"/' | paste -sd, -; else echo "\"无数据\""; fi)],
                    datasets: [{
                        label: '浏览次数',
                        data: [$(if [ -s "${TMP_DIR}/top_products.txt" ]; then cat "${TMP_DIR}/top_products.txt" | awk '{print $1}' | paste -sd, -; else echo "0"; fi)],
                        backgroundColor: '#10B981',
                        borderWidth: 1
                    }]
                },
                options: {
                    indexAxis: 'y', // 水平条形图
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        x: {
                            title: {
                                display: true,
                                text: '浏览次数'
                            }
                        },
                        y: {
                            title: {
                                display: true,
                                text: '商品'
                            }
                        }
                    },
                    plugins: {
                        title: {
                            display: true,
                            text: '热门商品TOP5'
                        }
                    }
                }
            });

            // 4. 转化率图表
            const conversionRateCtx = document.getElementById('conversionRateChart').getContext('2d');
            new Chart(conversionRateCtx, {
                type: 'bar',
                data: {
                    labels: [$(if [ -s "${TMP_DIR}/category_conversion.csv" ]; then cat "${TMP_DIR}/category_conversion.csv" | tail -n +2 | awk -F',' '{print $1}' | sed 's/^/"/;s/$/"/' | paste -sd, -; else echo "\"无数据\""; fi)],
                    datasets: [{
                        label: '浏览→购买转化率(%)',
                        data: [$(if [ -s "${TMP_DIR}/category_conversion.csv" ]; then cat "${TMP_DIR}/category_conversion.csv" | tail -n +2 | awk -F',' '{print $5}' | paste -sd, -; else echo "0"; fi)],
                        backgroundColor: '#F59E0B',
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        x: {
                            title: {
                                display: true,
                                text: '商品类别'
                            }
                        },
                        y: {
                            title: {
                                display: true,
                                text: '浏览→购买转化率(%)'
                            },
                            min: 0
                        }
                    },
                    plugins: {
                        title: {
                            display: true,
                            text: '商品类别转化率分析'
                        }
                    }
                }
            });
        });
    </script>
</body>
</html>
EOF

    show_progress 100 "HTML报告生成完成"
    echo -e "\n${GREEN}✓${NC} HTML报告生成完成"
    echo -e "\n${GREEN}分析完成！报告已生成：${REPORT_DIR}/analysis.html${NC}"
    echo -e "你可以在浏览器中打开此文件查看详细分析结果。"
}

# 主函数
main() {
    echo -e "${GREEN}===== 电商用户行为分析系统 ====${NC}"
    echo -e "${YELLOW}输入日志文件: ${INPUT_LOG}${NC}"
    echo -e "${YELLOW}商品信息文件: ${INPUT_PRODUCT}${NC}"
    echo -e "${YELLOW}输出目录: ${OUTPUT_DIR}${NC}"
    echo "--------------------------------"
    
    clean_data
    
    echo -e "\n${YELLOW}===== 并行执行分析任务 ====${NC}"
    
    PARALLEL_MODE=1 calculate_stats &
    PARALLEL_MODE=1 analyze_hourly_activity &
    PARALLEL_MODE=1 calculate_conversion &
    PARALLEL_MODE=1 analyze_behavior_path &
    PARALLEL_MODE=1 detect_anomalies &
    
    wait
    
    echo -e "\n${YELLOW}===== 生成HTML报告 ====${NC}"
    generate_html_report
    
    echo -e "\n${GREEN}✓ 所有分析任务已完成！${NC}"
}

# 执行主函数
main "$@"    