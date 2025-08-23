#!/bin/bash

# EZ-Theme Builder 快速删除脚本（紧急情况使用）

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}⚠️  紧急删除模式${NC}"
echo "=================================="
echo

# 确认删除
read -p "确定要快速删除 EZ-Theme Builder 吗？(输入 'DELETE' 确认): " confirm

if [ "$confirm" != "DELETE" ]; then
    echo "操作已取消"
    exit 0
fi

echo "开始快速删除..."

# 停止PM2进程
echo "停止PM2进程..."
pm2 stop ez-theme-builder 2>/dev/null || true
pm2 delete ez-theme-builder 2>/dev/null || true
pm2 save 2>/dev/null || true

# 删除项目目录
echo "删除项目目录..."
rm -rf /www/wwwroot/ez-theme-builder 2>/dev/null || true

# 删除临时目录
echo "删除临时目录..."
rm -rf /tmp/temp-* 2>/dev/null || true

# 清理npm缓存
echo "清理npm缓存..."
npm cache clean --force 2>/dev/null || true

echo -e "${GREEN}快速删除完成！${NC}"
echo
echo "注意："
echo "- 宝塔面板网站配置需要手动删除"
echo "- 数据库文件可能已删除，请确认"
echo "- 如需重新部署，请运行 deploy-baota.sh"
