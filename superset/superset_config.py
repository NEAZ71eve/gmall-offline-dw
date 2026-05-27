import os

# ============================================
# Superset 基础配置
# ============================================

# 安全配置
SECRET_KEY = 'gmall_superset_secret_key_2024_production'
WTF_CSRF_ENABLED = True
WTF_CSRF_TIME_LIMIT = 3600

# Web服务器配置
WEBSERVER_PORT = 8088
WEBSERVER_TIMEOUT = 60
WEBSERVER_WORKER_MULTIPLIER = 1
WEBSERVER_NUM_WORKERS = 4

# 数据库连接配置
SQLALCHEMY_DATABASE_URI = 'postgresql://superset:superset@localhost:5432/superset'
SQLALCHEMY_POOL_SIZE = 5
SQLALCHEMY_MAX_OVERFLOW = 10
SQLALCHEMY_POOL_TIMEOUT = 30
SQLALCHEMY_POOL_RECYCLE = 3600

# 数据查询配置
ROW_LIMIT = 50000
SQL_MAX_ROW = 100000
TIMEOUT = 300
SUPERSET_WORK_TIME = int(TIMEOUT)

# ============================================
# 缓存配置
# ============================================

CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_REDIS_URL': 'redis://localhost:6379/1',
    'CACHE_KEY_PREFIX': 'superset_',
    'CACHE_DEFAULT_TIMEOUT': 300,
}

DATA_CACHE_CONFIG = CACHE_CONFIG

# ============================================
# 功能开关
# ============================================

FEATURE_FLAGS = {
    'ENABLE_TEMPLATE_PROCESSING': True,
    'DASHBOARD_RBAC': True,
    'ENABLE_JAVASCRIPT_CONTROLS': True,
    'ALLOW_FULL_TABLE Viz': True,
    'DASHBOARD_NATIVE_FILTERS': True,
    'ESTIMATE_QUERY_COST': True,
    'ENABLE_EXPLORE_DRAG_DROP': True,
    'ENABLE_DND_WITH_CLICK_VIZ': True,
    'USE_ANALAGOUS_COLORS': True,
    'RISON_SHOW_DASHBOARD_ALERTS': True,
}

# ============================================
# 地图配置
# ============================================

MAPBOX_API_KEY = os.environ.get('MAPBOX_API_KEY', '')

# ============================================
# 日志配置
# ============================================

LOGGING_CONFIG = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'default': {
            'format': '%(asctime)s:%(levelname)s:%(name)s:%(message)s',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'default',
            'stream': 'ext://sys.stdout',
        },
        'file': {
            'class': 'logging.FileHandler',
            'formatter': 'default',
            'filename': '/var/log/superset/superset.log',
        },
    },
    'loggers': {
        'superset': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
            'propagate': True,
        },
    },
}

# ============================================
# Celery异步任务配置
# ============================================

class CeleryConfig:
    BROKER_URL = 'redis://localhost:6379/2'
    CELERY_IMPORTS = (
        'superset.sql_lab',
        'superset.tasks',
        'superset.tasks.scheduler',
    )
    CELERY_RESULT_BACKEND = 'redis://localhost:6379/3'
    CELERY_ANNOTATIONS = {
        'superset.sql_lab.get_sql_results': {
            'rate_limit': '100/s',
        },
        'superset.tasks.sync_dashboards': {
            'rate_limit': '1/h',
        },
    }
    CELERYD_CONCURRENCY = 4
    CELERY_TIMEZONE = 'Asia/Shanghai'

CELERY_CONFIG = CeleryConfig

# ============================================
# 认证配置
# ============================================

AUTH_TYPE = 1
AUTH_USER_REGISTRATION = True
AUTH_USER_REGISTRATION_ROLE = 'Public'
PUBLIC_ROLE_LIKE_GAMMA = True

# ============================================
# 跨域配置
# ============================================

ENABLE_CORS = True
CORS_OPTIONS = {
    'supports_credentials': True,
    'allow_headers': ['*'],
    'allow_methods': ['*'],
    'expose_headers': ['*'],
}

# ============================================
# 主题和UI配置
# ============================================

APP_ICON = '/static/assets/images/superset-logo-horiz.png'
APP_NAME = '电商数仓数据平台'

CUSTOM_SECURITY_HEADERS = {
    'X-Frame-Options': 'ALLOW',
    'X-Content-Type-Options': 'nosniff',
}

# ============================================
# Hive/PyHive配置
# ============================================

from sqlalchemy.engine import Engine
from sqlalchemy import event

PYHIVE_TIMEOUT = 300
HIVE_POLL_INTERVAL = 1
HIVE_MAX_POLL_INTERVAL = 60

# 数据源配置
PRESELECTED_SCHEMAS = {
    'gmall_ods': ['user_info', 'order_info', 'order_detail'],
    'gmall_dim': ['dim_user', 'dim_sku', 'dim_time'],
    'gmall_dwd': ['dwd_order_detail', 'dwd_order_info'],
    'gmall_dws': ['dws_gmv_stats', 'dws_user_stats', 'dws_sku_stats'],
    'gmall_ads': ['ads_gmv_day', 'ads_sku_sales_rank', 'ads_user_retention', 'ads_conversion_rate'],
}
