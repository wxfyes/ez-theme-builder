#!/bin/bash
# EZ-Theme Builder 修复缺失vite包问题
set -e

echo "🔧 修复缺失vite包问题..."

PROJECT_DIR="/www/wwwroot/ez-theme-builder"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 项目目录不存在: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

echo "🧹 清理前端依赖..."
cd frontend
rm -rf node_modules package-lock.json

echo "📋 检查package.json中的vite依赖..."
if grep -q '"vite"' package.json; then
    echo "✅ package.json中包含vite依赖"
    grep '"vite"' package.json
else
    echo "❌ package.json中缺少vite依赖，正在添加..."
    # 在devDependencies中添加vite
    sed -i '/"devDependencies": {/a\    "vite": "^5.4.0",' package.json
fi

echo "📥 强制安装vite包..."
# 先单独安装vite
npm install vite@^5.4.0 --save-dev --force

echo "🔍 验证vite包安装..."
if [ -d "node_modules/vite" ]; then
    echo "✅ vite包已安装"
    ls -la node_modules/vite/
    
    if [ -f "node_modules/vite/bin/vite.js" ]; then
        echo "✅ vite.js文件存在"
    else
        echo "❌ vite.js文件不存在"
    fi
else
    echo "❌ vite包安装失败"
fi

echo "📥 安装其他依赖..."
npm install --legacy-peer-deps

echo "🔍 检查node_modules/.bin目录..."
if [ -d "node_modules/.bin" ]; then
    echo "✅ .bin目录存在"
    ls -la node_modules/.bin/ | grep vite || echo "vite链接不存在"
else
    echo "❌ .bin目录不存在"
fi

echo "🔧 手动创建vite可执行文件链接..."
if [ -f "node_modules/vite/bin/vite.js" ]; then
    mkdir -p node_modules/.bin
    ln -sf ../vite/bin/vite.js node_modules/.bin/vite
    chmod +x node_modules/.bin/vite
    
    if [ -f "node_modules/.bin/vite" ]; then
        echo "✅ vite可执行文件链接已创建"
        ls -la node_modules/.bin/vite
    else
        echo "❌ vite可执行文件链接创建失败"
    fi
else
    echo "❌ 无法创建链接，vite.js文件不存在"
fi

echo "🧪 测试构建..."
BUILD_SUCCESS=false

# 方法1: 使用手动创建的链接
if [ -f "node_modules/.bin/vite" ]; then
    echo "使用手动创建的vite链接构建..."
    ./node_modules/.bin/vite build && BUILD_SUCCESS=true
fi

# 方法2: 使用npx
if [ "$BUILD_SUCCESS" = false ] && command -v npx >/dev/null 2>&1; then
    echo "使用npx vite构建..."
    npx vite build && BUILD_SUCCESS=true
fi

# 方法3: 直接调用node
if [ "$BUILD_SUCCESS" = false ] && [ -f "node_modules/vite/bin/vite.js" ]; then
    echo "直接使用node调用vite..."
    node node_modules/vite/bin/vite.js build && BUILD_SUCCESS=true
fi

# 方法4: 使用npm run build
if [ "$BUILD_SUCCESS" = false ]; then
    echo "使用npm run build..."
    npm run build && BUILD_SUCCESS=true
fi

# 方法5: 尝试全局安装vite
if [ "$BUILD_SUCCESS" = false ]; then
    echo "🔧 尝试全局安装vite..."
    npm install -g vite@^5.4.0
    
    if command -v vite >/dev/null 2>&1; then
        echo "使用全局vite构建..."
        vite build && BUILD_SUCCESS=true
    fi
fi

# 方法6: 使用yarn（如果可用）
if [ "$BUILD_SUCCESS" = false ] && command -v yarn >/dev/null 2>&1; then
    echo "🔧 尝试使用yarn..."
    rm -rf node_modules package-lock.json
    yarn install
    yarn build && BUILD_SUCCESS=true
fi

if [ "$BUILD_SUCCESS" = false ]; then
    echo "❌ 所有构建方法都失败了"
    echo "详细诊断信息："
    echo "=================================="
    echo "1. 检查package.json："
    cat package.json | grep -E '"vite"|"@vitejs/plugin-vue"'
    echo ""
    echo "2. 检查vite包："
    ls -la node_modules/vite/ 2>/dev/null || echo "vite包不存在"
    echo ""
    echo "3. 检查vite.js文件："
    ls -la node_modules/vite/bin/ 2>/dev/null || echo "vite/bin目录不存在"
    echo ""
    echo "4. 检查.bin目录："
    ls -la node_modules/.bin/ 2>/dev/null || echo ".bin目录不存在"
    echo ""
    echo "5. 检查npm缓存："
    npm cache verify
    echo ""
    echo "6. 尝试清理npm缓存并重新安装："
    npm cache clean --force
    rm -rf node_modules package-lock.json
    npm install --force
    echo "=================================="
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

echo "✅ vite包问题修复完成！"
echo "访问地址: http://你的域名"
echo "查看状态: pm2 status"
# EZ-Theme Builder 修复缺失vite包问题
set -e

echo "🔧 修复缺失vite包问题..."

PROJECT_DIR="/www/wwwroot/ez-theme-builder"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 项目目录不存在: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

echo "🧹 清理前端依赖..."
cd frontend
rm -rf node_modules package-lock.json

echo "📋 检查package.json中的vite依赖..."
if grep -q '"vite"' package.json; then
    echo "✅ package.json中包含vite依赖"
    grep '"vite"' package.json
else
    echo "❌ package.json中缺少vite依赖，正在添加..."
    # 在devDependencies中添加vite
    sed -i '/"devDependencies": {/a\    "vite": "^5.4.0",' package.json
fi

echo "📥 强制安装vite包..."
# 先单独安装vite
npm install vite@^5.4.0 --save-dev --force

echo "🔍 验证vite包安装..."
if [ -d "node_modules/vite" ]; then
    echo "✅ vite包已安装"
    ls -la node_modules/vite/
    
    if [ -f "node_modules/vite/bin/vite.js" ]; then
        echo "✅ vite.js文件存在"
    else
        echo "❌ vite.js文件不存在"
    fi
else
    echo "❌ vite包安装失败"
fi

echo "📥 安装其他依赖..."
npm install --legacy-peer-deps

echo "🔍 检查node_modules/.bin目录..."
if [ -d "node_modules/.bin" ]; then
    echo "✅ .bin目录存在"
    ls -la node_modules/.bin/ | grep vite || echo "vite链接不存在"
else
    echo "❌ .bin目录不存在"
fi

echo "🔧 手动创建vite可执行文件链接..."
if [ -f "node_modules/vite/bin/vite.js" ]; then
    mkdir -p node_modules/.bin
    ln -sf ../vite/bin/vite.js node_modules/.bin/vite
    chmod +x node_modules/.bin/vite
    
    if [ -f "node_modules/.bin/vite" ]; then
        echo "✅ vite可执行文件链接已创建"
        ls -la node_modules/.bin/vite
    else
        echo "❌ vite可执行文件链接创建失败"
    fi
else
    echo "❌ 无法创建链接，vite.js文件不存在"
fi

echo "🧪 测试构建..."
BUILD_SUCCESS=false

# 方法1: 使用手动创建的链接
if [ -f "node_modules/.bin/vite" ]; then
    echo "使用手动创建的vite链接构建..."
    ./node_modules/.bin/vite build && BUILD_SUCCESS=true
fi

# 方法2: 使用npx
if [ "$BUILD_SUCCESS" = false ] && command -v npx >/dev/null 2>&1; then
    echo "使用npx vite构建..."
    npx vite build && BUILD_SUCCESS=true
fi

# 方法3: 直接调用node
if [ "$BUILD_SUCCESS" = false ] && [ -f "node_modules/vite/bin/vite.js" ]; then
    echo "直接使用node调用vite..."
    node node_modules/vite/bin/vite.js build && BUILD_SUCCESS=true
fi

# 方法4: 使用npm run build
if [ "$BUILD_SUCCESS" = false ]; then
    echo "使用npm run build..."
    npm run build && BUILD_SUCCESS=true
fi

# 方法5: 尝试全局安装vite
if [ "$BUILD_SUCCESS" = false ]; then
    echo "🔧 尝试全局安装vite..."
    npm install -g vite@^5.4.0
    
    if command -v vite >/dev/null 2>&1; then
        echo "使用全局vite构建..."
        vite build && BUILD_SUCCESS=true
    fi
fi

# 方法6: 使用yarn（如果可用）
if [ "$BUILD_SUCCESS" = false ] && command -v yarn >/dev/null 2>&1; then
    echo "🔧 尝试使用yarn..."
    rm -rf node_modules package-lock.json
    yarn install
    yarn build && BUILD_SUCCESS=true
fi

if [ "$BUILD_SUCCESS" = false ]; then
    echo "❌ 所有构建方法都失败了"
    echo "详细诊断信息："
    echo "=================================="
    echo "1. 检查package.json："
    cat package.json | grep -E '"vite"|"@vitejs/plugin-vue"'
    echo ""
    echo "2. 检查vite包："
    ls -la node_modules/vite/ 2>/dev/null || echo "vite包不存在"
    echo ""
    echo "3. 检查vite.js文件："
    ls -la node_modules/vite/bin/ 2>/dev/null || echo "vite/bin目录不存在"
    echo ""
    echo "4. 检查.bin目录："
    ls -la node_modules/.bin/ 2>/dev/null || echo ".bin目录不存在"
    echo ""
    echo "5. 检查npm缓存："
    npm cache verify
    echo ""
    echo "6. 尝试清理npm缓存并重新安装："
    npm cache clean --force
    rm -rf node_modules package-lock.json
    npm install --force
    echo "=================================="
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

echo "✅ vite包问题修复完成！"
echo "访问地址: http://你的域名"
echo "查看状态: pm2 status"
