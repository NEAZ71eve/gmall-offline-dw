import os

ROW_LIMIT = 5000
WEBSERVER_PORT = 8088
SECRET_KEY = 'gmall_superset_secret_key_2024'

SQLALCHEMY_DATABASE_URI = 'sqlite:////opt/superset/superset.db'

CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_REDIS_URL': 'redis://localhost:6379/0'
}

FEATURE_FLAGS = {
    'ENABLE_TEMPLATE_PROCESSING': True,
    'DASHBOARD_RBAC': True
}

MAPBOX_API_KEY = os.environ.get('MAPBOX_API_KEY', '')

class CeleryConfig:
    BROKER_URL = 'redis://localhost:6379/0'
    CELERY_IMPORTS = (
        'superset.sql_lab',
        'superset.tasks',
    )
    CELERY_RESULT_BACKEND = 'redis://localhost:6379/0'
    CELERY_ANNOTATIONS = {
        'superset.sql_lab.get_sql_results': {
            'rate_limit': '100/s',
        },
        'superset.tasks.sync_dashboards': {
            'rate_limit': '1/h',
        },
    }

CELERY_CONFIG = CeleryConfig