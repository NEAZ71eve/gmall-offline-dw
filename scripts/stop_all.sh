#!/bin/bash
# ============================================================
# stop_all.sh - 停止全部 Docker 服务(保留数据卷)
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'; NC='\033[0m'
echo -e "${GREEN}[INFO]${NC}  停止 gmall 大数据平台..."
docker compose down
echo -e "${GREEN}[INFO]${NC}  全部服务已停止（数据卷已保留）"
echo -e "${GREEN}[INFO]${NC}  如需彻底清除数据: docker compose down -v"
