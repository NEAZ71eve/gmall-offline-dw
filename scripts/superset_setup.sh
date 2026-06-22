#!/bin/bash
# ============================================================
# superset_setup.sh - Superset 可视化平台初始化
# 1. 创建管理员 2. 初始化 DB 3. 安装 Hive 驱动 4. 添加数据源
# ============================================================
set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC}  $*"; }
step() { echo -e "${BLUE}[STEP]${NC} $*"; }

# 等待 Superset 就绪
step "1/5 等待 Superset 就绪..."
for i in $(seq 1 20); do
    if curl -s http://localhost:8089/health 2>/dev/null | grep -q "OK"; then
        info "Superset 健康检查通过"
        break
    fi
    sleep 5
done

# 创建管理员
step "2/5 创建管理员用户..."
docker exec superset superset fab create-admin \
    --username admin \
    --firstname Admin \
    --lastname GMall \
    --email admin@gmall.com \
    --password admin2024 2>/dev/null || echo "  (管理员已存在,跳过)"

# 初始化数据库
step "3/5 初始化 Superset 数据库..."
docker exec superset superset db upgrade 2>/dev/null
docker exec superset superset init 2>/dev/null
info "Superset 初始化完成"

# 安装 Hive 驱动 (pyhive)
step "4/5 安装 PyHive 驱动..."
docker exec superset pip install pyhive thrift thrift-sasl sqlalchemy-hive 2>/dev/null || \
    warn "PyHive 安装可能失败(容器无网络),不影响 MySQL 数据源使用"

# 添加数据源
step "5/5 配置数据源..."

# 用 Python API 添加 MySQL 数据源
docker exec -i superset python3 << 'PYEOF'
import sys
sys.path.insert(0, '/app/pythonpath')
from superset import create_app
from superset.extensions import db
from superset.models.core import Database

app = create_app()
with app.app_context():
    uri = 'mysql+mysqlconnector://gmall:gmall123@mysql:3306/gmall'
    existing = db.session.query(Database).filter_by(database_name='gmall_mysql').first()
    if not existing:
        db_mysql = Database(
            database_name='gmall_mysql',
            sqlalchemy_uri=uri,
            expose_in_sqllab=True,
            allow_ctas=True,
        )
        db.session.add(db_mysql)
        db.session.commit()
        print("  MySQL 数据源已添加: gmall_mysql")
    else:
        print("  MySQL 数据源已存在,跳过")

    # 尝试添加 Hive 数据源
    try:
        hive_uri = 'hive://hive-server:10000/default?auth=NONE'
        existing2 = db.session.query(Database).filter_by(database_name='gmall_hive').first()
        if not existing2:
            db_hive = Database(
                database_name='gmall_hive',
                sqlalchemy_uri=hive_uri,
                expose_in_sqllab=True,
                allow_ctas=True,
            )
            db.session.add(db_hive)
            db.session.commit()
            print("  Hive 数据源已添加: gmall_hive")
    except Exception as e:
        print(f"  Hive 数据源添加异常 (可手动添加): {e}")

db.session.close()
PYEOF

echo ""
info "========================================="
info "  Superset 可视化平台就绪"
info "  访问: http://localhost:8089"
info "  登录: admin / admin2024"
info ""
info "  手动操作:"
info "  1. Settings → Database Connections → 查看数据源"
info "  2. SQL Lab → 编写查询验证数据可访问"
info "  3. Charts → 创建图表 (GMV趋势/热门商品/转化漏斗)"
info "  4. Dashboard → 组装看板"
info "========================================="
