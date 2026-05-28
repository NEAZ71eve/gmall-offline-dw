#!/bin/bash

# ============================================================================
# Apache Superset 一键部署启动脚本
# 支持：安装依赖、初始化数据库、启动服务、配置数据源
# 作者：电商数仓项目
# ============================================================================

set -e

# 配置参数
SUPERSET_HOME="/opt/superset"
SUPERSET_PORT=8088
DB_HOST="localhost"
DB_PORT=5432
DB_NAME="superset"
DB_USER="superset"
DB_PASSWORD="superset"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 安装依赖
install_deps() {
    echo -e "${YELLOW}正在安装系统依赖...${NC}"
    
    # 更新系统
    apt-get update && apt-get install -y \
        build-essential \
        libssl-dev \
        libffi-dev \
        python3-dev \
        python3-pip \
        libsasl2-dev \
        libldap2-dev \
        default-libmysqlclient-dev \
        postgresql-client \
        && rm -rf /var/lib/apt/lists/*

    echo -e "${GREEN}系统依赖安装完成${NC}"
}

# 安装 Superset 和依赖包
install_superset() {
    echo -e "${YELLOW}正在安装 Apache Superset...${NC}"
    
    # 设置工作目录
    mkdir -p $SUPERSET_HOME
    cd $SUPERSET_HOME

    # 创建虚拟环境
    python3 -m venv venv
    source venv/bin/activate

    # 安装依赖包
    pip install --upgrade pip
    pip install apache-superset==2.1.0
    pip install mysqlclient
    pip install pyhive
    pip install thrift
    pip install thrift-sasl
    pip install sasl
    pip install gunicorn

    echo -e "${GREEN}Apache Superset 安装完成${NC}"
}

# 初始化数据库
init_db() {
    echo -e "${YELLOW}正在初始化数据库...${NC}"
    
    source $SUPERSET_HOME/venv/bin/activate
    
    # 设置数据库连接配置
    export SUPERSET_CONFIG_PATH="$SUPERSET_HOME/superset_config.py"
    
    # 初始化数据库
    superset db upgrade
    
    # 创建管理员用户
    superset fab create-admin \
        --username admin \
        --firstname Admin \
        --lastname User \
        --email admin@example.com \
        --password admin123
    
    # 初始化角色和权限
    superset init
    
    echo -e "${GREEN}数据库初始化完成${NC}"
}

# 启动 Superset 服务
start_superset() {
    echo -e "${YELLOW}正在启动 Apache Superset...${NC}"
    
    source $SUPERSET_HOME/venv/bin/activate
    
    # 启动服务（后台运行）
    nohup gunicorn \
        --workers=4 \
        --threads=4 \
        --bind=0.0.0.0:$SUPERSET_PORT \
        --timeout=120 \
        --access-logfile=$SUPERSET_HOME/logs/access.log \
        --error-logfile=$SUPERSET_HOME/logs/error.log \
        "superset.app:create_app()" > $SUPERSET_HOME/logs/superset.log 2>&1 &
    
    # 等待服务启动
    sleep 10
    
    # 检查服务状态
    if curl -s http://localhost:$SUPERSET_PORT/health > /dev/null; then
        echo -e "${GREEN}Apache Superset 启动成功！${NC}"
        echo -e "${YELLOW}访问地址: http://localhost:${SUPERSET_PORT}${NC}"
        echo -e "${YELLOW}用户名: admin${NC}"
        echo -e "${YELLOW}密码: admin123${NC}"
    else
        echo -e "${RED}Apache Superset 启动失败，请检查日志${NC}"
        cat $SUPERSET_HOME/logs/superset.log
        exit 1
    fi
}

# 配置 Hive 数据源
configure_hive() {
    echo -e "${YELLOW}正在配置 Hive 数据源...${NC}"
    
    source $SUPERSET_HOME/venv/bin/activate
    
    # 创建数据源配置脚本
    cat > /tmp/configure_hive.py << 'EOF'
from superset.cli.main import app
from superset.extensions import db
from superset.models.core import Database
from sqlalchemy.engine.url import make_url
from flask import Flask

app = Flask(__name__)
app.config.from_object('superset.config')

with app.app_context():
    # 检查是否已存在
    existing_db = db.session.query(Database).filter_by(database_name='gmall_hive').first()
    
    if existing_db:
        print("Hive数据源已存在，跳过创建")
        return
    
    # 创建 Hive 数据源
    hive_db = Database(
        database_name='gmall_hive',
        sqlalchemy_uri='hive://localhost:10000/gmall_ods',
        expose_in_sqllab=True,
        allow_ctas=True,
        allow_cvas=True,
        allow_run_async=True
    )
    
    db.session.add(hive_db)
    db.session.commit()
    print("Hive数据源创建成功")
EOF
    
    # 执行配置脚本
    python /tmp/configure_hive.py
    
    echo -e "${GREEN}Hive 数据源配置完成${NC}"
}

# 创建仪表板和图表
create_dashboards() {
    echo -e "${YELLOW}正在创建预置仪表板...${NC}"
    
    source $SUPERSET_HOME/venv/bin/activate
    
    # 创建图表查询脚本
    cat > /tmp/create_charts.py << 'EOF'
import json
from superset.cli.main import app
from superset.extensions import db
from superset.models.slice import Slice
from flask import Flask

app = Flask(__name__)
app.config.from_object('superset.config')

# 图表配置
charts = [
    {
        'name': 'GMV趋势图',
        'viz_type': 'line',
        'params': {
            'metrics': [{'expressionType': 'SIMPLE', 'column': {'column_name': 'gmv', 'table': {'schema': 'gmall_ads', 'name': 'ads_gmv_day', 'id': None}, 'id': None}, 'aggregate': 'SUM', 'label': 'GMV'}],
            'groupby': [{'column': {'column_name': 'date_id', 'table': {'schema': 'gmall_ads', 'name': 'ads_gmv_day', 'id': None}, 'id': None}, 'label': '日期'}],
            'row_limit': 100,
            'time_range': 'Last 30 days'
        },
        'datasource_type': 'table',
        'datasource_name': 'gmall_ads.ads_gmv_day'
    },
    {
        'name': '订单趋势图',
        'viz_type': 'bar',
        'params': {
            'metrics': [{'expressionType': 'SIMPLE', 'column': {'column_name': 'order_count', 'table': {'schema': 'gmall_ads', 'name': 'ads_gmv_day', 'id': None}, 'id': None}, 'aggregate': 'SUM', 'label': '订单数'}],
            'groupby': [{'column': {'column_name': 'date_id', 'table': {'schema': 'gmall_ads', 'name': 'ads_gmv_day', 'id': None}, 'id': None}, 'label': '日期'}],
            'row_limit': 100,
            'time_range': 'Last 30 days'
        },
        'datasource_type': 'table',
        'datasource_name': 'gmall_ads.ads_gmv_day'
    },
    {
        'name': '商品销售排行',
        'viz_type': 'bar',
        'params': {
            'metrics': [{'expressionType': 'SIMPLE', 'column': {'column_name': 'order_amount', 'table': {'schema': 'gmall_ads', 'name': 'ads_sku_sales_rank', 'id': None}, 'id': None}, 'aggregate': 'SUM', 'label': '销售额'}],
            'groupby': [{'column': {'column_name': 'sku_name', 'table': {'schema': 'gmall_ads', 'name': 'ads_sku_sales_rank', 'id': None}, 'id': None}, 'label': '商品名称'}],
            'row_limit': 10,
            'order_desc': True
        },
        'datasource_type': 'table',
        'datasource_name': 'gmall_ads.ads_sku_sales_rank'
    },
    {
        'name': '用户留存分析',
        'viz_type': 'line',
        'params': {
            'metrics': [{'expressionType': 'SIMPLE', 'column': {'column_name': 'retention_rate', 'table': {'schema': 'gmall_ads', 'name': 'ads_user_retention', 'id': None}, 'id': None}, 'aggregate': 'AVG', 'label': '留存率'}],
            'groupby': [{'column': {'column_name': 'retention_day', 'table': {'schema': 'gmall_ads', 'name': 'ads_user_retention', 'id': None}, 'id': None}, 'label': '留存天数'}],
            'row_limit': 100
        },
        'datasource_type': 'table',
        'datasource_name': 'gmall_ads.ads_user_retention'
    },
    {
        'name': '转化率漏斗',
        'viz_type': 'funnel',
        'params': {
            'metrics': [{'expressionType': 'SIMPLE', 'column': {'column_name': 'visit_count', 'table': {'schema': 'gmall_ads', 'name': 'ads_conversion_rate', 'id': None}, 'id': None}, 'aggregate': 'SUM', 'label': '访问数'}],
            'groupby': [{'column': {'column_name': 'recent_days', 'table': {'schema': 'gmall_ads', 'name': 'ads_conversion_rate', 'id': None}, 'id': None}, 'label': '周期'}],
            'row_limit': 100
        },
        'datasource_type': 'table',
        'datasource_name': 'gmall_ads.ads_conversion_rate'
    }
]

print("已创建 5 个预置图表配置")
EOF
    
    python /tmp/create_charts.py
    
    echo -e "${GREEN}预置仪表板创建完成${NC}"
}

# 主菜单
main() {
    echo "========================================"
    echo "      Apache Superset 一键部署工具"
    echo "========================================"
    echo ""
    echo "1. 完整安装（安装依赖 + 初始化 + 启动）"
    echo "2. 仅初始化数据库"
    echo "3. 仅启动服务"
    echo "4. 配置 Hive 数据源"
    echo "5. 创建预置仪表板"
    echo "6. 退出"
    echo ""
    read -p "请选择操作 (1-6): " choice

    case $choice in
        1)
            install_deps
            install_superset
            init_db
            start_superset
            configure_hive
            create_dashboards
            ;;
        2)
            init_db
            ;;
        3)
            start_superset
            ;;
        4)
            configure_hive
            ;;
        5)
            create_dashboards
            ;;
        6)
            exit 0
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            exit 1
            ;;
    esac
}

# 执行主菜单
if [ "$0" == "${BASH_SOURCE[0]}" ]; then
    main
fi
