#!/bin/bash

# EZ-Theme Builder 快速修复脚本

set -e

echo "🔧 快速修复构建工具问题..."

PROJECT_DIR="/www/wwwroot/ez-theme-builder"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 项目目录不存在: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

echo "📦 安装全局构建工具..."
npm install -g @vue/cli vite npx

echo "🧹 清理前端依赖..."
cd frontend
rm -rf node_modules package-lock.json

echo "📥 重新安装前端依赖..."
npm install

echo "🔧 修复构建脚本..."
# 备份package.json
cp package.json package.json.backup

# 修复构建脚本，使用npx
if grep -q '"build": "vite build"' package.json; then
    sed -i 's/"build": "vite build"/"build": "npx vite build"/g' package.json
    echo "✅ 修复Vite构建脚本"
elif grep -q '"build": "vue-cli-service build"' package.json; then
    sed -i 's/"build": "vue-cli-service build"/"build": "npx vue-cli-service build"/g' package.json
    echo "✅ 修复Vue CLI构建脚本"
fi

echo "🧪 测试构建..."
if npx vite --version &> /dev/null; then
    echo "使用Vite构建..."
    npx vite build
elif npx vue-cli-service --version &> /dev/null; then
    echo "使用Vue CLI构建..."
    npx vue-cli-service build
else
    echo "❌ 构建工具未找到"
    exit 1
fi

cd ..

echo "🚀 启动应用..."
mkdir -p logs builds temp data

# 创建PM2配置
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'ez-theme-builder',
    script: 'server.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '512M',
    env: {
      NODE_ENV: 'production',
      NODE_OPTIONS: '--max-old-space-size=512',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
EOF

# 启动PM2
pm2 stop ez-theme-builder 2>/dev/null || true
pm2 delete ez-theme-builder 2>/dev/null || true
pm2 start ecosystem.config.js
pm2 startup
pm2 save

echo "✅ 快速修复完成！"
echo "访问地址: http://你的域名"
echo "查看状态: pm2 status"
