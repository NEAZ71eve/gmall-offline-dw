#!/usr/bin/env python3
"""
gmall 电商 Spark 离线分析作业

功能:
  1. 按支付方式统计订单量与 GMV
  2. 热门 SKU Top10 (按销量)
  3. 用户等级分布 (VIP vs 普通)
  4. 转化漏斗分析 (view→cart→order→pay)

用法:
  spark-submit --master spark://spark-master:7077 \
    --jars /opt/bitnami/spark/jars/mysql-connector-j-8.0.33.jar \
    analytics.py 2024-01-22
"""
import sys
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sum as _sum, count, countDistinct, lit, round as _round

BIZ_DATE = sys.argv[1] if len(sys.argv) > 1 else "2024-01-22"

spark = SparkSession.builder \
    .appName(f"gmall-analytics-{BIZ_DATE}") \
    .config("spark.sql.adaptive.enabled", "true") \
    .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
    .getOrCreate()

spark.sparkContext.setLogLevel("WARN")

JDBC_URL = "jdbc:mysql://mysql:3306/gmall?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC"
PROPS = {"user": "gmall", "password": "gmall123", "driver": "com.mysql.cj.jdbc.Driver"}

print("=" * 60)
print(f"  gmall Spark 离线分析 - 日期: {BIZ_DATE}")
print("=" * 60)

try:
    # 加载源数据
    orders = spark.read.jdbc(url=JDBC_URL, table="order_info", properties=PROPS)
    details = spark.read.jdbc(url=JDBC_URL, table="order_detail", properties=PROPS)
    users = spark.read.jdbc(url=JDBC_URL, table="user_info", properties=PROPS)

    # ====== 1. 支付方式统计 ======
    print("\n[1] 按支付方式统计订单量:")
    orders.groupBy("payment_way") \
        .agg(count("*").alias("order_cnt"),
             _sum(col("total_amount").cast("double")).alias("gmv")) \
        .orderBy("order_cnt", ascending=False).show(10, False)

    # ====== 2. GMV 合计 ======
    gmv = orders.select(_sum(col("total_amount").cast("double"))).collect()[0][0]
    order_cnt = orders.count()
    paid = orders.filter(col("order_status") == "PAID").count()
    print(f"\n[2] GMV 总览:")
    print(f"  总订单: {order_cnt}, 已支付: {paid}")
    print(f"  总 GMV: ¥{gmv:,.2f}")
    print(f"  均单价: ¥{gmv/order_cnt:,.2f}" if order_cnt > 0 else "")

    # ====== 3. 热门 SKU Top10 ======
    print(f"\n[3] 热门 SKU Top10 (按销量):")
    details.groupBy("sku_id", "sku_name") \
        .agg(_sum("sku_num").alias("total_qty"),
             _sum(col("order_price").cast("double")).alias("total_gmv")) \
        .orderBy("total_qty", ascending=False).show(10, False)

    # ====== 4. 用户等级分布 ======
    print(f"\n[4] 用户等级分布:")
    users.groupBy("user_level") \
        .agg(count("*").alias("user_count")).show()

    # ====== 5. 每天订单趋势 ======
    print(f"\n[5] 每日订单趋势 (create_time前10位):")
    orders.withColumn("day", col("create_time").substr(1, 10)) \
        .groupBy("day") \
        .agg(count("*").alias("order_cnt"),
             _sum(col("total_amount").cast("double")).alias("gmv")) \
        .orderBy("day").show(20, False)

    # ====== 6. 客单价分层 ======
    print(f"\n[6] 客单价分布:")
    orders.select(
        col("total_amount").cast("double").alias("amount")).summary("count","min","25%","50%","75%","max").show()

    print("\n" + "=" * 60)
    print("  Spark 离线分析完成 ✓")
    print("=" * 60)

except Exception as e:
    print(f"\nSpark 作业异常: {e}")
    import traceback
    traceback.print_exc()

spark.stop()
