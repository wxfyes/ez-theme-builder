#!/bin/bash
# 简单清理脚本
set -e

echo "🧹 开始清理..."

# 停止 PM2 进程
echo "🛑 停止 PM2 进程..."
pm2 stop ez-theme-builder 2>/dev/null || true
pm2 delete ez-theme-builder 2>/dev/null || true

# 删除项目目录
echo "🗑️ 删除项目目录..."
rm -rf /www/wwwroot/ez-theme-builder

# 清理 npm 缓存
echo "🧹 清理 npm 缓存..."
npm cache clean --force

# 清理 PM2 日志
echo "🧹 清理 PM2 日志..."
pm2 flush

# 杀死端口 3000 的进程
echo "🔫 杀死端口 3000 的进程..."
pkill -f "node.*3000" 2>/dev/null || true

echo "✅ 清理完成！"
echo ""
echo "💡 现在可以重新运行 simple-install.sh 了"
# 简单清理脚本
set -e

echo "🧹 开始清理..."

# 停止 PM2 进程
echo "🛑 停止 PM2 进程..."
pm2 stop ez-theme-builder 2>/dev/null || true
pm2 delete ez-theme-builder 2>/dev/null || true

# 删除项目目录
echo "🗑️ 删除项目目录..."
rm -rf /www/wwwroot/ez-theme-builder

# 清理 npm 缓存
echo "🧹 清理 npm 缓存..."
npm cache clean --force

# 清理 PM2 日志
echo "🧹 清理 PM2 日志..."
pm2 flush

# 杀死端口 3000 的进程
echo "🔫 杀死端口 3000 的进程..."
pkill -f "node.*3000" 2>/dev/null || true

echo "✅ 清理完成！"
echo ""
echo "💡 现在可以重新运行 simple-install.sh 了"
