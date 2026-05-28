#!/bin/bash

# ============================================================================
# DolphinScheduler 一键部署启动脚本
# 支持：启动/停止/重启服务、查看状态、部署工作流
# 作者：电商数仓项目
# ============================================================================

set -e

# 配置参数
DOLPHINSCHEDULER_HOME="/opt/dolphinscheduler"
DOLPHINSCHEDULER_VERSION="3.2.0"
JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
MASTER_PORT=5678
WORKER_PORT=1234

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查 Java 环境
check_java() {
    if [ -z "$JAVA_HOME" ]; then
        echo -e "${RED}错误：JAVA_HOME 未设置${NC}"
        exit 1
    fi

    if [ ! -f "$JAVA_HOME/bin/java" ]; then
        echo -e "${RED}错误：Java 不存在于 $JAVA_HOME${NC}"
        exit 1
    fi

    echo -e "${GREEN}Java 环境检查通过${NC}"
}

# 下载并解压 DolphinScheduler
download_dolphinscheduler() {
    echo -e "${YELLOW}正在下载 DolphinScheduler ${DOLPHINSCHEDULER_VERSION}...${NC}"
    
    mkdir -p $DOLPHINSCHEDULER_HOME
    cd $DOLPHINSCHEDULER_HOME

    # 下载安装包
    wget -q https://dlcdn.apache.org/dolphinscheduler/${DOLPHINSCHEDULER_VERSION}/apache-dolphinscheduler-${DOLPHINSCHEDULER_VERSION}-bin.tar.gz
    
    # 解压
    tar -xzf apache-dolphinscheduler-${DOLPHINSCHEDULER_VERSION}-bin.tar.gz
    ln -s apache-dolphinscheduler-${DOLPHINSCHEDULER_VERSION}-bin current
    
    echo -e "${GREEN}DolphinScheduler 下载完成${NC}"
}

# 初始化数据库
init_db() {
    echo -e "${YELLOW}正在初始化数据库...${NC}"
    
    cd $DOLPHINSCHEDULER_HOME/current

    # 创建数据库表
    ./bin/dolphinscheduler-daemon.sh init

    echo -e "${GREEN}数据库初始化完成${NC}"
}

# 启动 Master
start_master() {
    echo -e "${YELLOW}正在启动 Master 服务...${NC}"
    
    cd $DOLPHINSCHEDULER_HOME/current
    ./bin/dolphinscheduler-daemon.sh start master-server
    
    # 等待启动
    sleep 5
    
    if pgrep -f "MasterServer" > /dev/null; then
        echo -e "${GREEN}Master 服务启动成功${NC}"
    else
        echo -e "${RED}Master 服务启动失败${NC}"
        cat logs/master-server.out
        exit 1
    fi
}

# 启动 Worker
start_worker() {
    echo -e "${YELLOW}正在启动 Worker 服务...${NC}"
    
    cd $DOLPHINSCHEDULER_HOME/current
    ./bin/dolphinscheduler-daemon.sh start worker-server
    
    # 等待启动
    sleep 5
    
    if pgrep -f "WorkerServer" > /dev/null; then
        echo -e "${GREEN}Worker 服务启动成功${NC}"
    else
        echo -e "${RED}Worker 服务启动失败${NC}"
        cat logs/worker-server.out
        exit 1
    fi
}

# 启动 API 服务
start_api() {
    echo -e "${YELLOW}正在启动 API 服务...${NC}"
    
    cd $DOLPHINSCHEDULER_HOME/current
    ./bin/dolphinscheduler-daemon.sh start api-server
    
    # 等待启动
    sleep 10
    
    if curl -s http://localhost:12345/dolphinscheduler/info > /dev/null; then
        echo -e "${GREEN}API 服务启动成功${NC}"
        echo -e "${YELLOW}API地址: http://localhost:12345${NC}"
    else
        echo -e "${RED}API 服务启动失败${NC}"
        cat logs/api-server.out
        exit 1
    fi
}

# 启动 UI
start_ui() {
    echo -e "${YELLOW}正在启动 UI 服务...${NC}"
    
    cd $DOLPHINSCHEDULER_HOME/current
    ./bin/dolphinscheduler-daemon.sh start ui-server
    
    # 等待启动
    sleep 10
    
    if curl -s http://localhost:8888 > /dev/null; then
        echo -e "${GREEN}UI 服务启动成功${NC}"
        echo -e "${YELLOW}UI地址: http://localhost:8888${NC}"
        echo -e "${YELLOW}用户名: admin${NC}"
        echo -e "${YELLOW}密码: dolphinscheduler123${NC}"
    else
        echo -e "${RED}UI 服务启动失败${NC}"
        cat logs/ui-server.out
        exit 1
    fi
}

# 启动所有服务
start_all() {
    echo -e "${YELLOW}正在启动 DolphinScheduler 所有服务...${NC}"
    
    start_master
    start_worker
    start_api
    start_ui
    
    echo -e "${GREEN}所有服务启动完成！${NC}"
}

# 停止所有服务
stop_all() {
    echo -e "${YELLOW}正在停止 DolphinScheduler 所有服务...${NC}"
    
    cd $DOLPHINSCHEDULER_HOME/current
    
    ./bin/dolphinscheduler-daemon.sh stop ui-server
    ./bin/dolphinscheduler-daemon.sh stop api-server
    ./bin/dolphinscheduler-daemon.sh stop worker-server
    ./bin/dolphinscheduler-daemon.sh stop master-server
    
    echo -e "${GREEN}所有服务停止完成${NC}"
}

# 查看状态
status() {
    echo -e "${YELLOW}正在查看服务状态...${NC}"
    
    cd $DOLPHINSCHEDULER_HOME/current
    
    echo ""
    echo "=== Master 状态 ==="
    ./bin/dolphinscheduler-daemon.sh status master-server
    
    echo ""
    echo "=== Worker 状态 ==="
    ./bin/dolphinscheduler-daemon.sh status worker-server
    
    echo ""
    echo "=== API 状态 ==="
    ./bin/dolphinscheduler-daemon.sh status api-server
    
    echo ""
    echo "=== UI 状态 ==="
    ./bin/dolphinscheduler-daemon.sh status ui-server
}

# 部署工作流
deploy_workflow() {
    echo -e "${YELLOW}正在部署工作流...${NC}"
    
    # 检查工作流配置文件
    if [ ! -f "/opt/gmall/dolphinscheduler/workflow_full.yaml" ]; then
        echo -e "${RED}工作流配置文件不存在${NC}"
        exit 1
    fi

    # 使用 API 部署工作流
    curl -s -X POST http://localhost:12345/dolphinscheduler/workflow/create \
        -H "Content-Type: application/json" \
        -H "token: admin:dolphinscheduler123" \
        -d @/opt/gmall/dolphinscheduler/workflow_full.yaml

    echo -e "${GREEN}工作流部署完成${NC}"
}

# 查看日志
logs() {
    echo -e "${YELLOW}正在查看日志...${NC}"
    
    cd $DOLPHINSCHEDULER_HOME/current
    
    case "${1:-all}" in
        master)
            tail -f logs/master-server.out
            ;;
        worker)
            tail -f logs/worker-server.out
            ;;
        api)
            tail -f logs/api-server.out
            ;;
        ui)
            tail -f logs/ui-server.out
            ;;
        all)
            echo "=== Master ==="
            tail -20 logs/master-server.out
            echo ""
            echo "=== Worker ==="
            tail -20 logs/worker-server.out
            echo ""
            echo "=== API ==="
            tail -20 logs/api-server.out
            echo ""
            echo "=== UI ==="
            tail -20 logs/ui-server.out
            ;;
        *)
            echo "用法: $0 logs {master|worker|api|ui|all}"
            ;;
    esac
}

# 主菜单
main() {
    case "${1:-help}" in
        install)
            check_java
            download_dolphinscheduler
            init_db
            ;;
        start)
            check_java
            start_all
            ;;
        stop)
            stop_all
            ;;
        restart)
            stop_all
            sleep 3
            start_all
            ;;
        status)
            status
            ;;
        deploy)
            deploy_workflow
            ;;
        logs)
            logs "${2:-all}"
            ;;
        init)
            init_db
            ;;
        help)
            echo "========================================"
            echo "     DolphinScheduler 管理工具"
            echo "========================================"
            echo ""
            echo "用法: $0 <命令>"
            echo ""
            echo "命令列表:"
            echo "  install    - 安装 DolphinScheduler"
            echo "  start      - 启动所有服务"
            echo "  stop       - 停止所有服务"
            echo "  restart    - 重启所有服务"
            echo "  status     - 查看服务状态"
            echo "  deploy     - 部署工作流"
            echo "  logs [type]- 查看日志 (master/worker/api/ui/all)"
            echo "  init       - 初始化数据库"
            echo "  help       - 显示此帮助信息"
            echo ""
            echo "访问地址:"
            echo "  UI: http://localhost:8888"
            echo "  API: http://localhost:12345"
            echo "  默认用户名: admin"
            echo "  默认密码: dolphinscheduler123"
            ;;
        *)
            echo "无效命令: $1"
            echo "使用 '$0 help' 查看帮助"
            exit 1
            ;;
    esac
}

# 执行主函数
if [ "$0" == "${BASH_SOURCE[0]}" ]; then
    main "$@"
fi
