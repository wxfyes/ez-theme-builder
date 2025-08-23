#!/bin/bash
# 宝塔面板 Node.js 管理器部署脚本
set -e

echo "🚀 宝塔面板 Node.js 管理器部署脚本"

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用root用户运行此脚本"
    exit 1
fi

# 检查宝塔面板是否安装
if [ ! -f "/etc/init.d/bt" ]; then
    echo "❌ 未检测到宝塔面板，请先安装宝塔面板"
    exit 1
fi

echo "✅ 检测到宝塔面板"

# 创建项目目录
PROJECT_DIR="/www/wwwroot/ez-theme-builder"
echo "📁 创建项目目录: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# 清理旧文件
echo "🧹 清理旧文件..."
rm -rf * .* 2>/dev/null || true

# 检查 Node.js 管理器
echo "📦 检查 Node.js 管理器..."
if [ ! -d "/www/server/nodejs" ]; then
    echo "❌ 未检测到 Node.js 管理器，请在宝塔面板中安装 Node.js 管理器"
    echo "💡 路径：宝塔面板 -> 软件商店 -> Node.js 管理器"
    exit 1
fi

# 设置 Node.js 环境
export PATH="/www/server/nodejs/22.18.0/bin:$PATH"
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

# 确保 vite 可用
echo "🔧 确保 vite 可用..."
if ! command -v vite &> /dev/null; then
    echo "📦 安装 vite 全局..."
    npm install -g vite @vitejs/plugin-vue
fi

# 尝试多种构建方式
echo "🔨 构建前端..."
if npm run build; then
    echo "✅ 构建成功"
elif npx vite build; then
    echo "✅ 使用 npx vite 构建成功"
elif node node_modules/vite/bin/vite.js build; then
    echo "✅ 使用直接路径构建成功"
else
    echo "❌ 所有构建方式都失败，尝试重新安装..."
    npm install --force
    npm run build
fi
cd ..

# 创建必要目录
echo "📁 创建必要目录..."
mkdir -p logs builds temp data

# 设置权限
echo "🔐 设置文件权限..."
chmod -R 755 .
chown -R www:www .

# 创建宝塔 Node.js 项目配置
echo "📝 创建宝塔 Node.js 项目配置..."
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
    },
    error_file: '/www/wwwroot/ez-theme-builder/logs/err.log',
    out_file: '/www/wwwroot/ez-theme-builder/logs/out.log',
    log_file: '/www/wwwroot/ez-theme-builder/logs/combined.log',
    time: true
  }]
}
EOF

# 创建启动脚本
echo "📝 创建启动脚本..."
cat > start.sh << 'EOF'
#!/bin/bash
cd /www/wwwroot/ez-theme-builder
export PATH="/www/server/nodejs/22.18.0/bin:$PATH"
export NODE_ENV=production
export PORT=3000
export NODE_OPTIONS="--max-old-space-size=512"
node server.js
EOF

chmod +x start.sh

# 创建停止脚本
echo "📝 创建停止脚本..."
cat > stop.sh << 'EOF'
#!/bin/bash
pkill -f "node.*server.js" || true
pkill -f "ez-theme-builder" || true
EOF

chmod +x stop.sh

# 创建重启脚本
echo "📝 创建重启脚本..."
cat > restart.sh << 'EOF'
#!/bin/bash
cd /www/wwwroot/ez-theme-builder
./stop.sh
sleep 2
./start.sh
EOF

chmod +x restart.sh

# 安装 PM2
echo "📦 安装 PM2..."
npm install -g pm2

# 启动应用
echo "🚀 启动应用..."
pm2 start ecosystem.config.js
pm2 startup
pm2 save

# 创建宝塔面板网站配置
echo "📝 创建宝塔面板网站配置..."
cat > baota-site-config.txt << 'EOF'
宝塔面板网站配置说明：

1. 在宝塔面板中创建网站：
   - 域名：你的域名或IP
   - 根目录：/www/wwwroot/ez-theme-builder

2. 在网站设置中配置反向代理：
   - 代理名称：ez-theme-builder
   - 目标URL：http://127.0.0.1:3000
   - 发送域名：$host

3. 或者直接访问：http://你的服务器IP:3000

4. 管理命令：
   - 启动：pm2 start ez-theme-builder
   - 停止：pm2 stop ez-theme-builder
   - 重启：pm2 restart ez-theme-builder
   - 查看日志：pm2 logs ez-theme-builder
   - 查看状态：pm2 status
EOF

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
echo "🎉 宝塔面板部署完成！"
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
echo "📝 宝塔面板配置说明已保存到: baota-site-config.txt"
echo ""
echo "💡 如果遇到问题，请运行: pm2 logs ez-theme-builder"
