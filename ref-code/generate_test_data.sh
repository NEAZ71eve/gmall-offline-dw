#!/bin/bash
# generate_test_data.sh - 生成电商用户行为测试数据（含1-5%错误数据）

# 定义输出文件（默认为当前目录下的user_behavior.log）
OUTPUT_FILE=${1:-"user_behavior.log"}

# 清空或创建文件
> "$OUTPUT_FILE"

# 错误数据比例（1-5%动态生成）
ERROR_RATE=$((1 + RANDOM % 5))  # 生成1-5%的错误率

# 生成1000条测试数据
echo "开始生成测试数据，共1000条记录（含${ERROR_RATE}%错误数据）..."

# 生成随机日期函数（2025年6月1-30日）
generate_random_date() {
    local base_date="2025-06-01"
    local random_days=$((RANDOM % 30))  # 生成0-29之间的随机数，覆盖6月1日到30日
    date -d "$base_date + $random_days days +$((RANDOM%24)) hours $((RANDOM%60)) minutes" "+%Y-%m-%d %H:%M:%S"
}

# 生成随机错误日期函数（MM/DD/YYYY格式）
generate_random_bad_date() {
    local base_date="2025-06-01"
    local random_days=$((RANDOM % 30))
    date -d "$base_date + $random_days days" "+%m/%d/%Y %H:%M:%S"
}

for i in {1..1000}; do
    # 随机决定是否生成错误数据
    if [ $((RANDOM%100)) -lt $ERROR_RATE ]; then
        # 生成错误数据
        case $((RANDOM%3)) in
            0)  # 错误日期格式 (MM/DD/YYYY)
                timestamp=$(generate_random_bad_date)
                user="user$((RANDOM%100))"
                ip="192.168.1.$((RANDOM%255))"
                action=("view_product" "add_to_cart" "purchase")
                product="product$((RANDOM%50))"
                echo "${timestamp},${user},${ip},${action[$((RANDOM%3))]},${product}" >> "$OUTPUT_FILE"
                ;;
            1)  # 商品ID为空
                timestamp=$(generate_random_date)
                user="user$((RANDOM%100))"
                ip="192.168.1.$((RANDOM%255))"
                action=("view_product" "add_to_cart" "purchase")
                echo "${timestamp},${user},${ip},${action[$((RANDOM%3))]}," >> "$OUTPUT_FILE"
                ;;
            2)  # 字段数量不足（4个字段）
                timestamp=$(generate_random_date)
                user="user$((RANDOM%100))"
                ip="192.168.1.$((RANDOM%255))"
                action=("view_product" "add_to_cart" "purchase")
                echo "${timestamp},${user},${ip},${action[$((RANDOM%3))]}" >> "$OUTPUT_FILE"
                ;;
        esac
    else
        # 生成正常数据
        timestamp=$(generate_random_date)
        user="user$((RANDOM%100))"
        ip="192.168.1.$((RANDOM%255))"
        action=("view_product" "add_to_cart" "purchase")
        product="product$((RANDOM%50))"
        echo "${timestamp},${user},${ip},${action[$((RANDOM%3))]},${product}" >> "$OUTPUT_FILE"
    fi
    
    # 显示进度
    if [ $((i%100)) -eq 0 ]; then
        echo -ne "已生成: ${i} 条记录...\r"
    fi
done

echo -e "测试数据生成完成！数据已保存至: ${GREEN}$OUTPUT_FILE${NC}"
echo "数据样例:"
head -n10 "$OUTPUT_FILE"