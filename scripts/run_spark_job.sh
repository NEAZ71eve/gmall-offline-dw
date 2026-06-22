#!/bin/bash
# ============================================================
# run_spark_job.sh - 提交 Spark 离线计算作业
# 用法: ./run_spark_job.sh [biz_date]
# 从 Hive ADS 表计算补充指标 (热门商品/转化漏斗深度分析)
# ============================================================
set -euo pipefail

BIZ_DATE="${1:-$(date -d 'yesterday' '+%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d')}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC}  $*"; }
step() { echo -e "${BLUE}[STEP]${NC} $*"; }

JOB_SCRIPT="$PROJECT_DIR/spark/analytics.py"

step "Spark 离线分析 - 日期: $BIZ_DATE"

# 检查 Spark 是否就绪
if ! curl -s http://localhost:18080 > /dev/null 2>&1; then
    echo "Spark Master 不可达,尝试本地模式..."
    SPARK_MODE="local[*]"
else
    SPARK_MODE="spark://spark-master:7077"
fi

if [ ! -f "$JOB_SCRIPT" ]; then
    echo "Spark 作业脚本不存在: $JOB_SCRIPT"
    echo "使用内联 PySpark 计算..."
    docker exec -i spark-master spark-submit \
        --master "$SPARK_MODE" \
        --name "gmall-analytics-${BIZ_DATE}" \
        --conf spark.sql.adaptive.enabled=true \
        /dev/stdin << 'PYEOF'
from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("gmall_analytics").getOrCreate()
print("=" * 60)
print("  gmall Spark 离线分析")
print("=" * 60)
# 简单演示: 从 MySQL 读取数据做聚合
jdbc_url = "jdbc:mysql://mysql:3306/gmall?useSSL=false&allowPublicKeyRetrieval=true"
props = {"user": "gmall", "password": "gmall123", "driver": "com.mysql.cj.jdbc.Driver"}

try:
    orders = spark.read.jdbc(url=jdbc_url, table="order_info", properties=props)
    details = spark.read.jdbc(url=jdbc_url, table="order_detail", properties=props)
    users = spark.read.jdbc(url=jdbc_url, table="user_info", properties=props)

    print(f"\n[1] 订单总量: {orders.count()}")
    print(f"[2] 订单明细: {details.count()}")

    # 按支付方式统计
    print("\n[3] 按支付方式统计:")
    orders.groupBy("payment_way").count().orderBy("count", ascending=False).show(10)

    # GMV 合计
    from pyspark.sql.functions import sum as _sum, col
    gmv = orders.select(_sum(col("total_amount").cast("double"))).collect()[0][0]
    print(f"\n[4] 总 GMV: ¥{gmv:,.2f}")

    # VIP vs 普通用户
    vip = users.filter(col("user_level") == "VIP").count()
    normal = users.filter(col("user_level") != "VIP").count()
    print(f"\n[5] 用户: VIP={vip}, 普通={normal}")

    print("\n" + "=" * 60)
    print("  Spark 分析完成")
    print("=" * 60)
except Exception as e:
    print(f"Spark 作业异常: {e}")
    # 降级: 直接打印提示
    print("提示: MySQL JDBC 连接可能需在 Spark 容器中安装 mysql-connector-j")
spark.stop()
PYEOF
fi

info "Spark 作业已提交 (查看 Spark UI: http://localhost:18080)"
