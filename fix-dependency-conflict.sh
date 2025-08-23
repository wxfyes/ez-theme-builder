#!/bin/bash
# EZ-Theme Builder 依赖冲突修复脚本
set -e

echo "🔧 修复依赖版本冲突..."

PROJECT_DIR="/www/wwwroot/ez-theme-builder"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 项目目录不存在: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

echo "🧹 清理前端依赖..."
cd frontend
rm -rf node_modules package-lock.json

echo "📋 分析依赖冲突..."
echo "问题：vite@7.1.3 与 @vitejs/plugin-vue@4.6.2 版本冲突"
echo "解决方案：降级 vite 到兼容版本或升级 plugin-vue"

echo "🔧 修复package.json中的依赖版本..."
# 备份package.json
cp package.json package.json.backup

# 检查并修复vite版本
if grep -q '"vite": "^7' package.json; then
    echo "降级vite到兼容版本..."
    sed -i 's/"vite": "^7[^"]*"/"vite": "^5.4.0"/g' package.json
    echo "✅ vite版本已降级到 ^5.4.0"
fi

# 检查并修复@vitejs/plugin-vue版本
if grep -q '"@vitejs/plugin-vue": "^4' package.json; then
    echo "升级@vitejs/plugin-vue到兼容版本..."
    sed -i 's/"@vitejs\/plugin-vue": "^4[^"]*"/"@vitejs\/plugin-vue": "^5.0.0"/g' package.json
    echo "✅ @vitejs/plugin-vue版本已升级到 ^5.0.0"
fi

echo "📥 使用legacy-peer-deps安装依赖..."
npm install --legacy-peer-deps

echo "🔍 验证依赖安装..."
if [ -f "node_modules/.bin/vite" ]; then
    echo "✅ vite可执行文件已创建"
    echo "vite版本: $(./node_modules/.bin/vite --version)"
else
    echo "⚠️  vite可执行文件未找到，尝试重建..."
    npm rebuild vite --legacy-peer-deps
fi

echo "🧪 测试构建..."
BUILD_SUCCESS=false

# 尝试构建
if [ -f "node_modules/.bin/vite" ]; then
    echo "使用本地vite构建..."
    ./node_modules/.bin/vite build && BUILD_SUCCESS=true
elif command -v npx >/dev/null 2>&1; then
    echo "使用npx vite构建..."
    npx vite build && BUILD_SUCCESS=true
else
    echo "尝试npm run build..."
    npm run build && BUILD_SUCCESS=true
fi

if [ "$BUILD_SUCCESS" = false ]; then
    echo "❌ 构建失败，尝试其他解决方案..."
    
    echo "🔧 方案2：使用--force强制安装..."
    rm -rf node_modules package-lock.json
    npm install --force
    
    echo "🧪 再次测试构建..."
    if [ -f "node_modules/.bin/vite" ]; then
        ./node_modules/.bin/vite build && BUILD_SUCCESS=true
    elif command -v npx >/dev/null 2>&1; then
        npx vite build && BUILD_SUCCESS=true
    else
        npm run build && BUILD_SUCCESS=true
    fi
fi

if [ "$BUILD_SUCCESS" = false ]; then
    echo "❌ 所有方案都失败了"
    echo "检查当前依赖版本："
    cat package.json | grep -E '"vite"|"@vitejs/plugin-vue"'
    echo "检查node_modules："
    ls -la node_modules/.bin/ | grep -E "vite|vue" || echo "没有找到相关文件"
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

echo "✅ 依赖冲突修复完成！"
echo "访问地址: http://你的域名"
echo "查看状态: pm2 status"



