#!/bin/bash
# ============================================================
# setup_vm.sh - Ubuntu 26.04 VM 环境一键部署脚本
# 用法: bash setup_vm.sh
# ============================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }
step()  { echo -e "\n${BLUE}════════════════════════════════════════════════${NC}"; echo -e "${BLUE}  $*${NC}"; echo -e "${BLUE}════════════════════════════════════════════════${NC}"; }

echo ""
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║     gmall 电商大数据平台 - Ubuntu VM 部署脚本              ║"
echo "  ║     适用: Ubuntu 20.04+ / 26.04                          ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo ""

# ====== Step 0: Check prerequisites ======
step "0/5 检查环境"

# Docker
if ! command -v docker &>/dev/null; then
    err "Docker 未安装。请先安装 Docker:"
    echo "  curl -fsSL https://get.docker.com | sudo bash"
    echo "  sudo usermod -aG docker \$USER"
    echo "  注销并重新登录"
    exit 1
fi
DOCKER_VER=$(docker --version 2>/dev/null | head -1)
info "Docker: $DOCKER_VER"

# Docker Compose
if docker compose version &>/dev/null; then
    COMPOSE_VER=$(docker compose version 2>/dev/null | head -1)
    info "Docker Compose: $COMPOSE_VER"
elif command -v docker-compose &>/dev/null; then
    COMPOSE_VER=$(docker-compose --version 2>/dev/null | head -1)
    info "docker-compose: $COMPOSE_VER"
    warn "建议升级到 docker compose (v2) 插件"
else
    err "Docker Compose 未安装"
    exit 1
fi

# Docker daemon running?
if ! docker info &>/dev/null; then
    warn "Docker daemon 未运行，尝试启动..."
    if systemctl is-active docker &>/dev/null; then
        info "docker 服务已在运行"
    else
        sudo systemctl start docker 2>/dev/null || {
            err "无法启动 Docker。请手动启动后再运行本脚本。"
            exit 1
        }
    fi
fi

# Memory check
MEM_GB=$(free -g | awk '/Mem:/{print $2}')
info "可用内存: ${MEM_GB}GB"
if [ "$MEM_GB" -lt 8 ]; then
    warn "内存不足 8GB, 建议分配 12GB+ 给 VM。"
    warn "若容器启动失败，请增加 VM 内存并重试。"
fi

# Disk check
DISK_GB=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
info "磁盘空闲: ${DISK_GB}GB"
if [ "$DISK_GB" -lt 10 ]; then
    warn "磁盘空间不足 10GB, 建议扩展。"
fi

# ====== Step 1: Setup permissions ======
step "1/5 设置脚本权限"
chmod +x scripts/*.sh 2>/dev/null || true
chmod +x spark/analytics.py 2>/dev/null || true
chmod +x superset/init_superset.py 2>/dev/null || true
info "所有脚本已设为可执行"

# ====== Step 2: Pull images ======
step "2/5 拉取 Docker 镜像 (约需 5-15 分钟)..."
docker compose pull 2>&1 | grep -E "Pulling|Pulled|Already|Error|error" || true

# Check if all images pulled
MISSING=0
IMAGES=(
    "bde2020/hadoop-namenode:2.0.0-hadoop3.2.1-java8"
    "bde2020/hadoop-datanode:2.0.0-hadoop3.2.1-java8"
    "bde2020/hadoop-resourcemanager:2.0.0-hadoop3.2.1-java8"
    "bde2020/hadoop-nodemanager:2.0.0-hadoop3.2.1-java8"
    "bde2020/hadoop-historyserver:2.0.0-hadoop3.2.1-java8"
    "bde2020/hive:2.3.2-postgresql-metastore"
    "bde2020/hive-metastore-postgresql:2.3.0"
    "bitnami/zookeeper:3.8"
    "mysql:8.0"
    "bitnami/spark:3.5"
    "apache/superset:3.1.0"
)
for img in "${IMAGES[@]}"; do
    if ! docker image inspect "$img" &>/dev/null; then
        warn "镜像未拉取成功: $img"
        MISSING=$((MISSING+1))
    fi
done

if [ "$MISSING" -gt 0 ]; then
    warn "$MISSING 个镜像拉取失败。可能需要配置 Docker 镜像加速器。"
    echo "  Docker Desktop: Settings → Docker Engine → registry-mirrors"
    echo "  或在 /etc/docker/daemon.json 添加国内镜像源"
else
    info "全部镜像拉取完成 ✓"
fi

# ====== Step 3: Start services ======
step "3/5 启动全部服务..."
bash scripts/start_all.sh

# ====== Step 4: Initialize ======
step "4/5 初始化环境 (HDFS目录 + Hive库 + MySQL校验)..."
bash scripts/cluster_init.sh

# ====== Step 5: Health check ======
step "5/5 集群健康巡检..."
bash scripts/status.sh

# ====== Done ======
echo ""
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║              部署完成！                                  ║"
echo "  ╠══════════════════════════════════════════════════════════╣"
echo "  ║  关键入口:                                              ║"
echo "  ║  HDFS NameNode:  http://localhost:9870                  ║"
echo "  ║  YARN RM:        http://localhost:8088                  ║"
echo "  ║  Spark Master:   http://localhost:18080                 ║"
echo "  ║  Superset:       http://localhost:8089                  ║"
echo "  ║    (admin / admin2024)                                  ║"
echo "  ╠══════════════════════════════════════════════════════════╣"
echo "  ║  下一步:                                                ║"
echo "  ║  ./scripts/cluster.sh etl   → 执行离线 ETL 全链路      ║"
echo "  ║  ./scripts/cluster.sh status → 集群巡检                ║"
echo "  ║  ./scripts/superset_setup.sh → 初始化 Superset         ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo ""
info "提示: 若镜像拉取失败，请配置 Docker 镜像加速器后重新运行本脚本。"
