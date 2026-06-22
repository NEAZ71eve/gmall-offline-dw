# Superset 配置文件 (docker 容器内挂载路径: /app/pythonpath/)
import os

SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY", "change-me-gmall-superset-2024")

# Superset 元数据库使用外部 MySQL
SQLALCHEMY_DATABASE_URI = (
    f"mysql+mysqlconnector://{os.environ.get('DATABASE_USER','gmall')}:"
    f"{os.environ.get('DATABASE_PASSWORD','gmall123')}@"
    f"{os.environ.get('DATABASE_HOST','mysql')}:"
    f"{os.environ.get('DATABASE_PORT','3306')}/"
    f"{os.environ.get('DATABASE_DB','gmall')}"
)

# 允许大查询
SQLLAB_CTAS_NO_LIMIT = True
ROW_LIMIT = 50000

# 启用缩略图
ENABLE_THUMBNAIL_CACHE = False

# 中文/英文对照
LANGUAGES = {"en": {"flag": "us", "name": "English"}, "zh": {"flag": "cn", "name": "中文"}}

# 数据源配置
PREVENT_UNSAFE_DB_CONNECTIONS = False

# CORS
ENABLE_CORS = True
CORS_OPTIONS = {"supports_credentials": True, "allow_headers": ["*"], "resources": ["*"], "origins": ["*"]}

# 功能开关
FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
    "DASHBOARD_CROSS_FILTERS": True,
    "DASHBOARD_RBAC": False,
}
