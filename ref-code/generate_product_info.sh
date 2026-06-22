#!/bin/bash
# generate_product_info.sh - 生成商品信息测试数据（无错误数据）

# 定义输出文件（默认为当前目录下的product_info.csv）
OUTPUT_FILE=${1:-"product_info.csv"}

# 定义商品类别
categories=("电子产品" "服饰" "家居用品" "食品" "图书" "美妆" "运动器材")

# 清空或创建文件
> "$OUTPUT_FILE"

# 生成50个商品信息（无错误数据）
echo "开始生成商品信息（无错误数据）..."
for i in {0..49}; do
    # 生成正常数据
    product="product$i"
    category=${categories[$((RANDOM%${#categories[@]}))]}
    case $category in
        "电子产品") name="电子产品-$i"; price=$((200 + RANDOM%3000)) ;;
        "服饰") name="服饰-$i"; price=$((50 + RANDOM%500)) ;;
        "家居用品") name="家居用品-$i"; price=$((30 + RANDOM%200)) ;;
        "食品") name="食品-$i"; price=$((10 + RANDOM%100)) ;;
        "图书") name="图书-$i"; price=$((20 + RANDOM%80)) ;;
        "美妆") name="美妆-$i"; price=$((50 + RANDOM%300)) ;;
        "运动器材") name="运动器材-$i"; price=$((100 + RANDOM%1000)) ;;
    esac
    echo "${product},${name},${price},${category}" >> "$OUTPUT_FILE"
done

echo -e "商品信息生成完成！数据已保存至: ${GREEN}$OUTPUT_FILE${NC}"
echo "数据样例:"
head -n10 "$OUTPUT_FILE"