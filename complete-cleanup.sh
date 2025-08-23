#!/bin/bash
# EZ-Theme Builder 完全清理脚本
set -e

echo "🧹 EZ-Theme Builder 完全清理脚本"
echo "⚠️  警告：此脚本将删除所有相关文件和配置"
echo ""

# 确认操作
read -p "确定要完全清理所有EZ-Theme Builder相关文件吗？(y/N): " confirm
if [[ $confirm != [yY] ]]; then
    echo "❌ 操作已取消"
    exit 0
fi

echo "🚀 开始完全清理..."

# 第一步：停止所有相关进程
echo "📋 步骤1: 停止所有相关进程..."
pm2 stop ez-theme-builder 2>/dev/null || echo "PM2进程不存在"
pm2 delete ez-theme-builder 2>/dev/null || echo "PM2进程已删除"

# 停止Docker容器
docker-compose down 2>/dev/null || echo "Docker Compose已停止"
docker stop ez-theme-builder 2>/dev/null || echo "Docker容器已停止"
docker rm ez-theme-builder 2>/dev/null || echo "Docker容器已删除"

echo "✅ 进程清理完成"

# 第二步：删除项目目录
echo "📋 步骤2: 删除项目目录..."
rm -rf /www/wwwroot/ez-theme-builder
rm -rf /root/ez-theme-builder
rm -rf /home/*/ez-theme-builder
echo "✅ 项目目录删除完成"

# 第三步：清理npm缓存和全局包
echo "📋 步骤3: 清理npm缓存和全局包..."
npm cache clean --force
npm uninstall -g pm2 @vue/cli vite npx 2>/dev/null || echo "全局包清理完成"
npm cache verify
echo "✅ npm清理完成"

# 第四步：清理Docker
echo "📋 步骤4: 清理Docker..."
# 停止所有容器
docker stop $(docker ps -aq) 2>/dev/null || echo "Docker容器已停止"

# 删除所有容器
docker rm $(docker ps -aq) 2>/dev/null || echo "Docker容器已删除"

# 删除相关镜像
docker rmi $(docker images | grep ez-theme-builder | awk '{print $3}') 2>/dev/null || echo "Docker镜像已删除"

# 清理Docker系统
docker system prune -af
docker volume prune -f
echo "✅ Docker清理完成"

# 第五步：清理系统日志和临时文件
echo "📋 步骤5: 清理系统日志和临时文件..."
rm -rf /var/log/ez-theme-builder* 2>/dev/null || echo "系统日志已清理"
rm -rf /tmp/ez-theme-builder* 2>/dev/null || echo "临时文件已清理"
find /tmp -name "*ez-theme*" -delete 2>/dev/null || echo "临时文件搜索完成"
find /var/tmp -name "*ez-theme*" -delete 2>/dev/null || echo "var/tmp清理完成"
echo "✅ 日志和临时文件清理完成"

# 第六步：清理环境变量
echo "📋 步骤6: 清理环境变量..."
sed -i '/JWT_SECRET/d' ~/.bashrc
sed -i '/NODE_OPTIONS/d' ~/.bashrc
sed -i '/NODE_ENV/d' ~/.bashrc
source ~/.bashrc
echo "✅ 环境变量清理完成"

# 第七步：清理端口占用
echo "📋 步骤7: 清理端口占用..."
lsof -ti:3000 | xargs kill -9 2>/dev/null || echo "端口3000已释放"
echo "✅ 端口清理完成"

# 第八步：验证清理结果
echo "📋 步骤8: 验证清理结果..."
echo ""

echo "🔍 验证项目目录:"
ls -la /www/wwwroot/ | grep ez-theme-builder || echo "✅ 项目目录已删除"

echo "🔍 验证PM2进程:"
pm2 list | grep ez-theme-builder || echo "✅ PM2进程已清理"

echo "🔍 验证Docker容器:"
docker ps -a | grep ez-theme-builder || echo "✅ Docker容器已清理"

echo "🔍 验证端口占用:"
netstat -tulpn | grep :3000 || echo "✅ 端口3000已释放"

echo "🔍 验证全局npm包:"
npm list -g | grep -E "(pm2|@vue/cli|vite)" || echo "✅ 全局npm包已清理"

echo ""
echo "🎉 完全清理完成！"
echo ""
echo "📋 清理内容总结:"
echo "✅ 项目目录和文件"
echo "✅ PM2进程和配置"
echo "✅ Docker容器和镜像"
echo "✅ npm缓存和全局包"
echo "✅ 系统日志和临时文件"
echo "✅ 环境变量"
echo "✅ 端口占用"
echo ""
echo "💡 现在你可以重新开始部署了！"
echo "推荐使用Docker部署: wget -O deploy-docker.sh https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/deploy-docker.sh && chmod +x deploy-docker.sh && ./deploy-docker.sh"
