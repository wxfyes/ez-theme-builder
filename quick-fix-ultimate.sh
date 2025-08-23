#!/bin/bash
# EZ-Theme Builder 终极修复脚本
set -e

echo "🔧 终极修复构建工具问题..."

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

echo "🔍 检查构建工具..."
# 检查vite是否在package.json中
if grep -q '"vite"' package.json; then
    echo "✅ 发现Vite依赖"
    # 确保vite被正确安装
    if [ ! -f "node_modules/.bin/vite" ]; then
        echo "⚠️  Vite未在.bin目录中找到，重新安装..."
        npm install vite --save-dev
    fi
fi

# 检查vue-cli-service是否在package.json中
if grep -q '"@vue/cli-service"' package.json; then
    echo "✅ 发现Vue CLI依赖"
    # 确保vue-cli-service被正确安装
    if [ ! -f "node_modules/.bin/vue-cli-service" ]; then
        echo "⚠️  Vue CLI Service未在.bin目录中找到，重新安装..."
        npm install @vue/cli-service --save-dev
    fi
fi

echo "🔧 修复构建脚本..."
# 备份package.json
cp package.json package.json.backup

# 检查并修复构建脚本，使用npx而不是本地路径
if grep -q '"build": "vite build"' package.json; then
    sed -i 's/"build": "vite build"/"build": "npx vite build"/g' package.json
    echo "✅ 修复Vite构建脚本（使用npx）"
elif grep -q '"build": "vue-cli-service build"' package.json; then
    sed -i 's/"build": "vue-cli-service build"/"build": "npx vue-cli-service build"/g' package.json
    echo "✅ 修复Vue CLI构建脚本（使用npx）"
fi

echo "🧪 测试构建..."
# 尝试多种构建方式
BUILD_SUCCESS=false

# 方法1: 使用npx
if command -v npx >/dev/null 2>&1; then
    echo "尝试使用npx构建..."
    if npx vite --version &> /dev/null; then
        echo "使用npx vite构建..."
        npx vite build && BUILD_SUCCESS=true
    elif npx vue-cli-service --version &> /dev/null; then
        echo "使用npx vue-cli-service构建..."
        npx vue-cli-service build && BUILD_SUCCESS=true
    fi
fi

# 方法2: 使用本地.bin目录
if [ "$BUILD_SUCCESS" = false ]; then
    echo "尝试使用本地构建工具..."
    if [ -f "node_modules/.bin/vite" ]; then
        echo "使用本地Vite构建..."
        ./node_modules/.bin/vite build && BUILD_SUCCESS=true
    elif [ -f "node_modules/.bin/vue-cli-service" ]; then
        echo "使用本地Vue CLI构建..."
        ./node_modules/.bin/vue-cli-service build && BUILD_SUCCESS=true
    fi
fi

# 方法3: 使用npm run build
if [ "$BUILD_SUCCESS" = false ]; then
    echo "尝试使用npm run build..."
    npm run build && BUILD_SUCCESS=true
fi

# 方法4: 直接调用node
if [ "$BUILD_SUCCESS" = false ]; then
    echo "尝试直接调用node..."
    if [ -f "node_modules/vite/bin/vite.js" ]; then
        echo "使用node调用vite..."
        node node_modules/vite/bin/vite.js build && BUILD_SUCCESS=true
    elif [ -f "node_modules/@vue/cli-service/bin/vue-cli-service.js" ]; then
        echo "使用node调用vue-cli-service..."
        node node_modules/@vue/cli-service/bin/vue-cli-service.js build && BUILD_SUCCESS=true
    fi
fi

if [ "$BUILD_SUCCESS" = false ]; then
    echo "❌ 所有构建方法都失败了"
    echo "检查package.json中的依赖..."
    cat package.json | grep -E '"vite"|"@vue/cli-service"'
    echo "检查node_modules目录..."
    ls -la node_modules/.bin/ | grep -E "vite|vue-cli"
    exit 1
else
    echo "✅ 构建成功！"
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

echo "✅ 终极修复完成！"
echo "访问地址: http://你的域名"
echo "查看状态: pm2 status"
