#!/bin/bash
# 最简单的 EZ-Theme Builder 安装脚本
set -e

echo "🚀 开始最简单的安装方式..."

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用root用户运行此脚本"
    exit 1
fi

# 创建项目目录
PROJECT_DIR="/www/wwwroot/ez-theme-builder"
echo "📁 创建项目目录: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# 清理旧文件
echo "🧹 清理旧文件..."
rm -rf * .* 2>/dev/null || true

# 安装 Node.js 18
echo "📦 安装 Node.js 18..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - || true
    apt-get install -y nodejs || true
fi

echo "✅ Node.js 版本: $(node --version)"
echo "✅ npm 版本: $(npm --version)"

# 下载项目
echo "📥 下载项目文件..."
wget -O ez-theme-builder.zip https://github.com/wxfyes/ez-theme-builder/archive/refs/heads/main.zip

if [ ! -f "ez-theme-builder.zip" ]; then
    echo "❌ 下载失败，尝试备用下载方式..."
    curl -L -o ez-theme-builder.zip https://github.com/wxfyes/ez-theme-builder/archive/refs/heads/main.zip
fi

# 解压项目
echo "📂 解压项目文件..."
unzip -o ez-theme-builder.zip
mv ez-theme-builder-main/* .
rm -rf ez-theme-builder-main ez-theme-builder.zip

# 安装后端依赖
echo "📦 安装后端依赖..."
npm install --force --no-optional

# 安装前端依赖并构建
echo "📦 安装前端依赖..."
cd frontend
npm install --force --no-optional

echo "🔨 构建前端..."
npm run build
cd ..

# 创建必要目录
echo "📁 创建必要目录..."
mkdir -p logs builds temp data

# 设置权限
echo "🔐 设置文件权限..."
chmod -R 755 .
chown -R www-data:www-data .

# 创建启动脚本
echo "📝 创建启动脚本..."
cat > start.sh << 'EOF'
#!/bin/bash
cd /www/wwwroot/ez-theme-builder
export NODE_ENV=production
export PORT=3000
export NODE_OPTIONS="--max-old-space-size=512"
node server.js
EOF

chmod +x start.sh

# 创建 PM2 配置文件
echo "📝 创建 PM2 配置..."
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'ez-theme-builder',
    script: 'server.js',
    cwd: '/www/wwwroot/ez-theme-builder',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '512M',
    env: {
      NODE_ENV: 'production',
      PORT: 3000,
      NODE_OPTIONS: '--max-old-space-size=512'
    }
  }]
}
EOF

# 安装 PM2
echo "📦 安装 PM2..."
npm install -g pm2

# 启动应用
echo "🚀 启动应用..."
pm2 start ecosystem.config.js
pm2 startup
pm2 save

# 检查状态
echo "📊 检查应用状态..."
sleep 3
pm2 status

# 检查端口
echo "🔍 检查端口 3000..."
if netstat -tlnp | grep :3000; then
    echo "✅ 应用已成功启动在端口 3000"
else
    echo "❌ 端口 3000 未监听，检查日志..."
    pm2 logs ez-theme-builder --lines 10
fi

echo ""
echo "🎉 安装完成！"
echo ""
echo "📋 管理命令："
echo "  启动: pm2 start ez-theme-builder"
echo "  停止: pm2 stop ez-theme-builder"
echo "  重启: pm2 restart ez-theme-builder"
echo "  查看日志: pm2 logs ez-theme-builder"
echo "  查看状态: pm2 status"
echo ""
echo "🌐 访问地址: http://你的服务器IP:3000"
echo ""
echo "💡 如果遇到问题，请运行: pm2 logs ez-theme-builder"
