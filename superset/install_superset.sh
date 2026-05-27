#!/bin/bash

echo "================================================================================"
echo "                      Apache Superset 安装与启动脚本"
echo "================================================================================"
echo ""

# Superset 安装函数
install_superset() {
    echo "[步骤1] 安装 Superset..."
    echo "--------------------------------------------------------------------"

    # 创建虚拟环境
    echo "创建 Python 虚拟环境..."
    python3 -m venv superset_env

    # 激活虚拟环境
    source superset_env/bin/activate

    # 安装依赖
    echo "安装 Superset 及相关依赖..."
    pip install --upgrade pip setuptools wheel
    pip install apache-superset[postgres,hive]
    pip install pyhive[hive]
    pip install thrift
    pip install sasl
    pip install thrift-sasl
    pip install psycopg2-binary

    echo "安装完成！"
    echo ""
}

# 初始化 Superset
init_superset() {
    echo "[步骤2] 初始化 Superset 数据库..."
    echo "--------------------------------------------------------------------"

    source superset_env/bin/activate

    # 创建配置目录
    mkdir -p /opt/superset
    cp /mnt/d/s/作业/superset/superset_config.py /opt/superset/

    # 设置环境变量
    export SUPERSET_CONFIG_PATH=/opt/superset/superset_config.py
    export FLASK_APP=superset

    # 初始化数据库
    superset db upgrade

    # 创建管理员用户
    echo "创建管理员用户..."
    superset fab create-admin \
        --username admin \
        --firstname Admin \
        --lastname User \
        --email admin@example.com \
        --password admin123

    # 加载示例数据（可选）
    echo "加载示例数据（可选）..."
    # superset load_examples

    # 初始化权限
    superset init

    echo "Superset 初始化完成！"
    echo ""
}

# 配置 Hive 连接
config_hive() {
    echo "[步骤3] 配置 Hive 数据库连接..."
    echo "--------------------------------------------------------------------"

    source superset_env/bin/activate

    # 安装 PyHive
    pip install pyhive[hive] thrift-sasl

    echo "Hive 连接配置完成！"
    echo ""
}

# 启动 Superset
start_superset() {
    echo "[步骤4] 启动 Superset 服务..."
    echo "--------------------------------------------------------------------"

    source superset_env/bin/activate
    export SUPERSET_CONFIG_PATH=/opt/superset/superset_config.py
    export FLASK_APP=superset

    # 启动 Superset
    nohup superset run -h 0.0.0.0 -p 8088 > /tmp/superset.log 2>&1 &
    SUPERSET_PID=$!

    echo "Superset 服务已启动 (PID: $SUPERSET_PID)"
    echo "Web 界面地址: http://localhost:8088"
    echo ""
}

# 启动 Celery Worker
start_celery_worker() {
    echo "[步骤5] 启动 Celery Worker..."
    echo "--------------------------------------------------------------------"

    source superset_env/bin/activate
    export SUPERSET_CONFIG_PATH=/opt/superset/superset_config.py

    # 启动 Worker
    nohup celery -A superset.tasks.celery_app:app worker \
        --loglevel=info > /tmp/celery_worker.log 2>&1 &

    echo "Celery Worker 已启动"
    echo ""
}

# 主函数
main() {
    echo "请选择操作："
    echo "1. 完整安装 (install)"
    echo "2. 仅初始化 (init)"
    echo "3. 仅启动服务 (start)"
    echo "4. 配置数据源 (config)"
    echo "5. 完整部署 (all)"
    echo ""

    read -p "请输入选项 [1-5]: " choice

    case $choice in
        1)
            install_superset
            init_superset
            config_hive
            start_superset
            start_celery_worker
            ;;
        2)
            init_superset
            ;;
        3)
            start_superset
            start_celery_worker
            ;;
        4)
            config_hive
            ;;
        5)
            install_superset
            init_superset
            config_hive
            start_superset
            start_celery_worker
            ;;
        *)
            echo "无效选项，使用完整安装..."
            install_superset
            init_superset
            config_hive
            start_superset
            start_celery_worker
            ;;
    esac

    echo "================================================================================"
    echo "                         Superset 部署完成！"
    echo "================================================================================"
    echo ""
    echo "访问地址: http://localhost:8088"
    echo "用户名: admin"
    echo "密码: admin123"
    echo ""
    echo "日志文件:"
    echo "  - Superset: /tmp/superset.log"
    echo "  - Celery: /tmp/celery_worker.log"
    echo ""
}

# 执行主函数
main
