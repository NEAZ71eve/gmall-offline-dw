# ============================================================================
# Superset配置文件
# 电商数仓可视化大屏配置
# ============================================================================

# 数据库连接配置
DATABASE_CONNECTIONS = {
    "hive_gmall": {
        "database": "gmall",
        "driver": "hive",
        "host": "gmall-hiveserver2",
        "port": 10000,
        "username": "",
        "password": "",
        "database_name": "gmall",
        "extra": {
            "auth": "NONE"
        }
    },
    "hive_ads": {
        "database": "gmall_ads",
        "driver": "hive",
        "host": "gmall-hiveserver2",
        "port": 10000,
        "username": "",
        "password": "",
        "database_name": "gmall_ads",
        "extra": {
            "auth": "NONE"
        }
    },
    "hive_all": {
        "database": "default",
        "driver": "hive",
        "host": "gmall-hiveserver2",
        "port": 10000,
        "username": "",
        "password": "",
        "database_name": "default",
        "extra": {
            "auth": "NONE"
        }
    }
}

# 仪表盘配置
DASHBOARDS = [
    {
        "dashboard_title": "电商数据分析大屏",
        "dashboard_description": "实时监控电商核心指标",
        "slug": "ecommerce_dashboard",
        "charts": [
            {
                "chart_type": "big_number",
                "chart_title": "今日GMV",
                "dataset": "gmall_ads.ads_gmv_day",
                "params": {
                    "metric": "SUM(gmv)",
                    "groupby": ["dt"],
                    "filters": [
                        {"col": "dt", "op": "==", "val": "${today}"},
                        {"col": "recent_days", "op": "==", "val": 1}
                    ],
                    "color": "#26A69A"
                },
                "position": {"x": 0, "y": 0, "width": 4, "height": 3}
            },
            {
                "chart_type": "big_number",
                "chart_title": "今日订单数",
                "dataset": "gmall_ads.ads_gmv_day",
                "params": {
                    "metric": "SUM(order_count)",
                    "groupby": ["dt"],
                    "filters": [
                        {"col": "dt", "op": "==", "val": "${today}"},
                        {"col": "recent_days", "op": "==", "val": 1}
                    ],
                    "color": "#42A5F5"
                },
                "position": {"x": 4, "y": 0, "width": 4, "height": 3}
            },
            {
                "chart_type": "big_number",
                "chart_title": "下单人数",
                "dataset": "gmall_ads.ads_gmv_day",
                "params": {
                    "metric": "SUM(order_user_count)",
                    "groupby": ["dt"],
                    "filters": [
                        {"col": "dt", "op": "==", "val": "${today}"},
                        {"col": "recent_days", "op": "==", "val": 1}
                    ],
                    "color": "#9C27B0"
                },
                "position": {"x": 8, "y": 0, "width": 4, "height": 3}
            },
            {
                "chart_type": "line",
                "chart_title": "GMV趋势(近30天)",
                "dataset": "gmall_ads.ads_gmv_day",
                "params": {
                    "x_axis": "dt",
                    "y_axis": ["gmv"],
                    "filters": [
                        {"col": "recent_days", "op": "==", "val": 1},
                        {"col": "dt", "op": ">=", "val": "${30_days_ago}"}
                    ],
                    "line_style": "solid",
                    "show_area": True
                },
                "position": {"x": 0, "y": 3, "width": 8, "height": 5}
            },
            {
                "chart_type": "bar",
                "chart_title": "商品销售排行",
                "dataset": "gmall_ads.ads_sku_sales_rank",
                "params": {
                    "x_axis": "sku_name",
                    "y_axis": ["order_amount"],
                    "filters": [
                        {"col": "recent_days", "op": "==", "val": 7},
                        {"col": "rank", "op": "<=", "val": 10}
                    ],
                    "sort_by": "order_amount",
                    "sort_asc": False
                },
                "position": {"x": 8, "y": 3, "width": 4, "height": 5}
            },
            {
                "chart_type": "heatmap",
                "chart_title": "用户留存矩阵",
                "dataset": "gmall_ads.ads_user_retention",
                "params": {
                    "x_axis": "create_date",
                    "y_axis": "retention_day",
                    "value": "retention_rate",
                    "filters": [
                        {"col": "dt", "op": "==", "val": "${today}"}
                    ]
                },
                "position": {"x": 0, "y": 8, "width": 6, "height": 4}
            },
            {
                "chart_type": "donut",
                "chart_title": "转化率漏斗",
                "dataset": "gmall_ads.ads_conversion_rate",
                "params": {
                    "labels": ["visit_to_cart_rate", "cart_to_order_rate", "order_to_payment_rate"],
                    "values": ["访问到加购", "加购到下单", "下单到支付"],
                    "filters": [
                        {"col": "recent_days", "op": "==", "val": 1},
                        {"col": "dt", "op": "==", "val": "${today}"}
                    ]
                },
                "position": {"x": 6, "y": 8, "width": 6, "height": 4}
            },
            {
                "chart_type": "table",
                "chart_title": "地区销售排名",
                "dataset": "gmall_ads.ads_province_sale",
                "params": {
                    "columns": ["province_name", "gmv", "order_count", "order_user_count", "rank"],
                    "filters": [
                        {"col": "recent_days", "op": "==", "val": 7},
                        {"col": "rank", "op": "<=", "val": 10}
                    ],
                    "sort_by": "rank",
                    "sort_asc": True
                },
                "position": {"x": 0, "y": 12, "width": 12, "height": 4}
            }
        ]
    },
    {
        "dashboard_title": "用户分析面板",
        "dashboard_description": "用户行为分析",
        "slug": "user_analysis",
        "charts": [
            {
                "chart_type": "big_number",
                "chart_title": "日活用户(DAU)",
                "dataset": "gmall_ads.ads_user_activity",
                "params": {
                    "metric": "MAX(daily_active_users)",
                    "filters": [
                        {"col": "dt", "op": "==", "val": "${today}"},
                        {"col": "recent_days", "op": "==", "val": 1}
                    ],
                    "color": "#26A69A"
                },
                "position": {"x": 0, "y": 0, "width": 4, "height": 3}
            },
            {
                "chart_type": "big_number",
                "chart_title": "周活用户(WAU)",
                "dataset": "gmall_ads.ads_user_activity",
                "params": {
                    "metric": "MAX(weekly_active_users)",
                    "filters": [
                        {"col": "dt", "op": "==", "val": "${today}"},
                        {"col": "recent_days", "op": "==", "val": 7}
                    ],
                    "color": "#42A5F5"
                },
                "position": {"x": 4, "y": 0, "width": 4, "height": 3}
            },
            {
                "chart_type": "big_number",
                "chart_title": "月活用户(MAU)",
                "dataset": "gmall_ads.ads_user_activity",
                "params": {
                    "metric": "MAX(monthly_active_users)",
                    "filters": [
                        {"col": "dt", "op": "==", "val": "${today}"},
                        {"col": "recent_days", "op": "==", "val": 30}
                    ],
                    "color": "#9C27B0"
                },
                "position": {"x": 8, "y": 0, "width": 4, "height": 3}
            },
            {
                "chart_type": "line",
                "chart_title": "DAU趋势",
                "dataset": "gmall_ads.ads_user_activity",
                "params": {
                    "x_axis": "dt",
                    "y_axis": ["daily_active_users"],
                    "filters": [
                        {"col": "recent_days", "op": "==", "val": 1},
                        {"col": "dt", "op": ">=", "val": "${30_days_ago}"}
                    ]
                },
                "position": {"x": 0, "y": 3, "width": 8, "height": 5}
            },
            {
                "chart_type": "bar",
                "chart_title": "留存率对比",
                "dataset": "gmall_ads.ads_user_retention",
                "params": {
                    "x_axis": "retention_day",
                    "y_axis": ["retention_rate"],
                    "filters": [
                        {"col": "dt", "op": "==", "val": "${today}"},
                        {"col": "retention_day", "op": "IN", "val": [1, 7, 14, 30]}
                    ],
                    "groupby": ["retention_day"]
                },
                "position": {"x": 8, "y": 3, "width": 4, "height": 5}
            },
            {
                "chart_type": "bar",
                "chart_title": "用户活跃度分布",
                "dataset": "gmall_dws.dws_user_action_stats",
                "params": {
                    "x_axis": "user_id",
                    "y_axis": ["order_count"],
                    "filters": [
                        {"col": "dt", "op": "==", "val": "${today}"}
                    ],
                    "limit": 20
                },
                "position": {"x": 0, "y": 8, "width": 12, "height": 4}
            }
        ]
    },
    {
        "dashboard_title": "商品销售分析",
        "dashboard_description": "商品销售数据",
        "slug": "product_analysis",
        "charts": [
            {
                "chart_type": "big_number",
                "chart_title": "热销商品TOP1",
                "dataset": "gmall_ads.ads_sku_sales_rank",
                "params": {
                    "metric": "MAX(sku_name)",
                    "filters": [
                        {"col": "recent_days", "op": "==", "val": 7},
                        {"col": "rank", "op": "==", "val": 1}
                    ],
                    "color": "#26A69A"
                },
                "position": {"x": 0, "y": 0, "width": 6, "height": 2}
            },
            {
                "chart_type": "big_number",
                "chart_title": "热销金额",
                "dataset": "gmall_ads.ads_sku_sales_rank",
                "params": {
                    "metric": "MAX(order_amount)",
                    "filters": [
                        {"col": "recent_days", "op": "==", "val": 7},
                        {"col": "rank", "op": "==", "val": 1}
                    ],
                    "color": "#42A5F5"
                },
                "position": {"x": 6, "y": 0, "width": 6, "height": 2}
            },
            {
                "chart_type": "bar",
                "chart_title": "商品销售TOP20",
                "dataset": "gmall_ads.ads_sku_sales_rank",
                "params": {
                    "x_axis": "sku_name",
                    "y_axis": ["order_amount"],
                    "filters": [
                        {"col": "recent_days", "op": "==", "val": 7},
                        {"col": "rank", "op": "<=", "val": 20}
                    ],
                    "sort_by": "order_amount",
                    "sort_asc": False,
                    "horizontal": True
                },
                "position": {"x": 0, "y": 2, "width": 12, "height": 6}
            },
            {
                "chart_type": "table",
                "chart_title": "商品复购分析",
                "dataset": "gmall_ads.ads_sku_repurchase_analysis",
                "params": {
                    "columns": ["sku_name", "total_order_count", "repurchase_rate", "avg_repurchase_times"],
                    "filters": [
                        {"col": "dt", "op": "==", "val": "${today}"},
                        {"col": "repurchase_rate", "op": ">", "val": 10}
                    ],
                    "sort_by": "repurchase_rate",
                    "sort_asc": False
                },
                "position": {"x": 0, "y": 8, "width": 12, "height": 4}
            }
        ]
    }
]

# 报表配置
REPORTS = [
    {
        "report_title": "每日销售报表",
        "report_slug": "daily_sales_report",
        "schedule": "0 0 8 * * ?",
        "recipients": ["admin@example.com", "business@example.com"],
        "content_template": """
# 每日销售报表

## 📊 核心指标

| 指标 | 今日值 | 同比 | 环比 |
|------|--------|------|------|
| GMV | {{ gmv }} | {{ gmv_yoy }}% | {{ gmv_mom }}% |
| 订单数 | {{ order_count }} | {{ order_count_yoy }}% | {{ order_count_mom }}% |
| 下单人数 | {{ order_user_count }} | - | - |
| 客单价 | {{ avg_order_amount }} | - | - |

## 📈 GMV趋势

近7天GMV: {{ gmv_7d }}
近30天GMV: {{ gmv_30d }}

## 🏆 热销商品TOP5

{{ top_products }}

## 📍 地区排名

{{ province_rank }}

---
*报表生成时间: {{ report_time }}*
        """,
        "data_queries": [
            {"query_name": "gmv_data", "table": "gmall_ads.ads_gmv_trend", "filters": [{"col": "dt", "op": "==", "val": "${today}"}]},
            {"query_name": "top_products", "table": "gmall_ads.ads_sku_sales_rank", "filters": [{"col": "recent_days", "op": "==", "val": 7}, {"col": "rank", "op": "<=", "val": 5}]},
            {"query_name": "province_rank", "table": "gmall_ads.ads_province_sale", "filters": [{"col": "recent_days", "op": "==", "val": 7}, {"col": "rank", "op": "<=", "val": 5}]}
        ]
    }
]

# 数据源配置
DATA_SOURCES = {
    "hive": {
        "type": "hive",
        "host": "gmall-hiveserver2",
        "port": 10000,
        "database": "default",
        "extra": {
            "auth": "NONE",
            "kerberos_auth": False,
            "kerberos_service_name": "hive"
        }
    }
}