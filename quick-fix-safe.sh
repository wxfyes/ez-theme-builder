#!/bin/bash
# EZ-Theme Builder 安全快速修复脚本（无全局安装）
set -e

echo "🔧 安全快速修复构建工具问题..."

PROJECT_DIR="/www/wwwroot/ez-theme-builder"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 项目目录不存在: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

echo "🧹 清理前端依赖..."
cd frontend
rm -rf node_modules package-lock.json

echo "📥 重新安装前端依赖..."
npm install

echo "🔧 修复构建脚本..."
# 备份package.json
cp package.json package.json.backup

# 检查并修复构建脚本，使用本地路径
if grep -q '"build": "vite build"' package.json; then
    sed -i 's/"build": "vite build"/"build": ".\/node_modules\/.bin\/vite build"/g' package.json
    echo "✅ 修复Vite构建脚本（使用本地路径）"
elif grep -q '"build": "vue-cli-service build"' package.json; then
    sed -i 's/"build": "vue-cli-service build"/"build": ".\/node_modules\/.bin\/vue-cli-service build"/g' package.json
    echo "✅ 修复Vue CLI构建脚本（使用本地路径）"
fi

echo "🧪 测试构建..."
# 只使用本地依赖进行构建
if [ -f "node_modules/.bin/vite" ]; then
    echo "使用本地Vite构建..."
    ./node_modules/.bin/vite build
elif [ -f "node_modules/.bin/vue-cli-service" ]; then
    echo "使用本地Vue CLI构建..."
    ./node_modules/.bin/vue-cli-service build
else
    echo "❌ 本地构建工具未找到"
    echo "尝试使用npm run build..."
    npm run build
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

echo "✅ 安全快速修复完成！"
echo "访问地址: http://你的域名"
echo "查看状态: pm2 status"
