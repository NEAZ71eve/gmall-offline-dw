# Apache Superset 配置文件
# 生产级配置

import os
from datetime import timedelta

# 基础配置
SECRET_KEY = 'gmall_superset_secret_key_2024'
SQLALCHEMY_DATABASE_URI = 'sqlite:////opt/superset/superset.db'

# 安全配置
SESSION_COOKIE_SECURE = False
SESSION_COOKIE_HTTPONLY = True
PERMANENT_SESSION_LIFETIME = timedelta(days=1)

# 缓存配置
CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 300,
    'CACHE_KEY_PREFIX': 'superset_',
    'CACHE_REDIS_URL': 'redis://localhost:6379/0',
}

# 异步任务配置
class CeleryConfig:
    BROKER_URL = 'redis://localhost:6379/1'
    CELERY_RESULT_BACKEND = 'redis://localhost:6379/1'
    CELERY_IMPORTS = (
        'superset.sql_lab',
        'superset.tasks',
    )
    CELERY_TASK_PROTOCOL = 1
    CELERYD_PREFETCH_MULTIPLIER = 10
    CELERY_ACKS_LATE = True
    CELERY_ANNOTATIONS = {
        'sql_lab.get_sql_results': {
            'rate_limit': '100/s',
        },
        'email_reports.send': {
            'rate_limit': '1/s',
            'time_limit': 120,
            'soft_time_limit': 150,
        },
    }

CELERY_CONFIG = CeleryConfig

# 特性开关
FEATURE_FLAGS = {
    'ENABLE_TEMPLATE_PROCESSING': True,
    'DASHBOARD_RBAC': True,
    'ENABLE_EXPLORE_JSON_CSRF_PROTECTION': True,
}

# 数据库连接池配置
SQLALCHEMY_ENGINE_OPTIONS = {
    'pool_size': 50,
    'max_overflow': 100,
    'pool_timeout': 30,
    'pool_recycle': 1800,
}

# 上传配置
UPLOAD_FOLDER = '/tmp/superset_uploads'
MAX_CONTENT_LENGTH = 50 * 1024 * 1024  # 50MB

# 时间格式
DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S'
DATE_FORMAT = '%Y-%m-%d'

# 日志配置
LOG_LEVEL = 'INFO'
LOG_FILE = '/opt/superset/logs/superset.log'

# 图表配置
DEFAULT_RENDERING_TIMEOUT = 30
MAX_ROWS_TO_DISPLAY = 10000
MAX_SERIES_PER_CHART = 100

# 国际化
BABEL_DEFAULT_LOCALE = 'zh'
BABEL_DEFAULT_TIMEZONE = 'Asia/Shanghai'

# 数据源配置
PRESELECTED_SCHEMAS = {
    'gmall_ods': [
        'ods_user_info',
        'ods_order_info', 
        'ods_order_detail',
        'ods_sku_info',
        'ods_activity_info',
        'ods_coupon_info',
    ],
    'gmall_dim': [
        'dim_user',
        'dim_sku',
        'dim_time',
        'dim_province',
        'dim_trademark',
    ],
    'gmall_dwd': [
        'dwd_order_detail',
        'dwd_order_info',
        'dwd_payment_info',
        'dwd_action',
        'dwd_order_refund',
    ],
    'gmall_dws': [
        'dws_gmv_stats',
        'dws_user_action_stats',
        'dws_sku_stats',
        'dws_user_stats',
        'dws_province_stats',
    ],
    'gmall_ads': [
        'ads_gmv_day',
        'ads_user_retention',
        'ads_sku_sales_rank',
        'ads_conversion_rate',
        'ads_user_repurchase_rate',
        'ads_user_activity',
        'ads_category_sale_analysis',
        'ads_province_sale',
    ],
}

# SQL Lab 配置
SQLLAB_DEFAULT_DBID = None
SQLLAB_TIMEOUT = 600
SQLLAB_ASYNC_TIME_LIMIT_SEC = 3600
SQLLAB_MAX_ROW = 10000
SQLLAB_CTAS_NO_LIMIT = True

# 仪表盘配置
DASHBOARD_CROSS_FILTERS = True
DASHBOARD_NATIVE_FILTERS = True

# 告警配置
ALERT_REPORTS_NOTIFICATION_DRY_RUN = False
ALERT_REPORTS_ENABLE = True
