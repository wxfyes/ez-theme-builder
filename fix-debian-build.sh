#!/bin/bash
# EZ-Theme Builder Debian 11 专用修复脚本
set -e

echo "🔧 Debian 11 专用构建修复脚本..."

PROJECT_DIR="/www/wwwroot/ez-theme-builder"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 项目目录不存在: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

echo "🧹 清理前端依赖..."
cd frontend
rm -rf node_modules package-lock.json

echo "📋 检查系统环境..."
echo "系统版本: $(cat /etc/os-release | grep PRETTY_NAME)"
echo "Node.js版本: $(node --version)"
echo "npm版本: $(npm --version)"

echo "🔧 修复package.json中的依赖版本..."
# 备份package.json
cp package.json package.json.backup

# 确保使用兼容的版本
if grep -q '"vite": "^7' package.json; then
    sed -i 's/"vite": "^7[^"]*"/"vite": "^5.4.0"/g' package.json
    echo "✅ vite版本已降级到 ^5.4.0"
fi

if grep -q '"@vitejs/plugin-vue": "^4' package.json; then
    sed -i 's/"@vitejs\/plugin-vue": "^4[^"]*"/"@vitejs\/plugin-vue": "^5.0.0"/g' package.json
    echo "✅ @vitejs/plugin-vue版本已升级到 ^5.0.0"
fi

echo "📥 使用legacy-peer-deps安装依赖..."
npm install --legacy-peer-deps

echo "🔍 检查vite包安装情况..."
if [ -d "node_modules/vite" ]; then
    echo "✅ vite包已安装"
    ls -la node_modules/vite/bin/ 2>/dev/null || echo "vite/bin目录不存在"
    
    # 检查vite.js文件
    if [ -f "node_modules/vite/bin/vite.js" ]; then
        echo "✅ vite.js文件存在"
        
        # 手动创建可执行文件链接
        echo "🔧 手动创建vite可执行文件链接..."
        mkdir -p node_modules/.bin
        ln -sf ../vite/bin/vite.js node_modules/.bin/vite
        chmod +x node_modules/.bin/vite
        
        if [ -f "node_modules/.bin/vite" ]; then
            echo "✅ vite可执行文件链接已创建"
        else
            echo "❌ vite可执行文件链接创建失败"
        fi
    else
        echo "❌ vite.js文件不存在"
    fi
else
    echo "❌ vite包未安装"
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

# 方法5: 尝试使用Vue CLI
if [ "$BUILD_SUCCESS" = false ]; then
    echo "尝试使用Vue CLI构建..."
    if [ -f "node_modules/.bin/vue-cli-service" ]; then
        ./node_modules/.bin/vue-cli-service build && BUILD_SUCCESS=true
    elif command -v npx >/dev/null 2>&1; then
        npx vue-cli-service build && BUILD_SUCCESS=true
    fi
fi

# 方法6: 强制重新安装并尝试
if [ "$BUILD_SUCCESS" = false ]; then
    echo "🔧 强制重新安装并尝试..."
    rm -rf node_modules package-lock.json
    npm install --force
    
    # 重新创建链接
    if [ -f "node_modules/vite/bin/vite.js" ]; then
        mkdir -p node_modules/.bin
        ln -sf ../vite/bin/vite.js node_modules/.bin/vite
        chmod +x node_modules/.bin/vite
        ./node_modules/.bin/vite build && BUILD_SUCCESS=true
    fi
fi

if [ "$BUILD_SUCCESS" = false ]; then
    echo "❌ 所有构建方法都失败了"
    echo "详细诊断信息："
    echo "=================================="
    echo "1. 检查package.json："
    cat package.json | grep -E '"vite"|"@vitejs/plugin-vue"'
    echo ""
    echo "2. 检查node_modules目录："
    ls -la node_modules/.bin/ 2>/dev/null || echo "node_modules/.bin目录不存在"
    echo ""
    echo "3. 检查vite包："
    ls -la node_modules/vite/ 2>/dev/null || echo "vite包不存在"
    echo ""
    echo "4. 检查vite.js文件："
    ls -la node_modules/vite/bin/ 2>/dev/null || echo "vite/bin目录不存在"
    echo ""
    echo "5. 尝试手动运行vite："
    if [ -f "node_modules/vite/bin/vite.js" ]; then
        node node_modules/vite/bin/vite.js --version || echo "vite无法运行"
    else
        echo "vite.js文件不存在"
    fi
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

echo "✅ Debian 11 构建修复完成！"
echo "访问地址: http://你的域名"
echo "查看状态: pm2 status"
# EZ-Theme Builder Debian 11 专用修复脚本
set -e

echo "🔧 Debian 11 专用构建修复脚本..."

PROJECT_DIR="/www/wwwroot/ez-theme-builder"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 项目目录不存在: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

echo "🧹 清理前端依赖..."
cd frontend
rm -rf node_modules package-lock.json

echo "📋 检查系统环境..."
echo "系统版本: $(cat /etc/os-release | grep PRETTY_NAME)"
echo "Node.js版本: $(node --version)"
echo "npm版本: $(npm --version)"

echo "🔧 修复package.json中的依赖版本..."
# 备份package.json
cp package.json package.json.backup

# 确保使用兼容的版本
if grep -q '"vite": "^7' package.json; then
    sed -i 's/"vite": "^7[^"]*"/"vite": "^5.4.0"/g' package.json
    echo "✅ vite版本已降级到 ^5.4.0"
fi

if grep -q '"@vitejs/plugin-vue": "^4' package.json; then
    sed -i 's/"@vitejs\/plugin-vue": "^4[^"]*"/"@vitejs\/plugin-vue": "^5.0.0"/g' package.json
    echo "✅ @vitejs/plugin-vue版本已升级到 ^5.0.0"
fi

echo "📥 使用legacy-peer-deps安装依赖..."
npm install --legacy-peer-deps

echo "🔍 检查vite包安装情况..."
if [ -d "node_modules/vite" ]; then
    echo "✅ vite包已安装"
    ls -la node_modules/vite/bin/ 2>/dev/null || echo "vite/bin目录不存在"
    
    # 检查vite.js文件
    if [ -f "node_modules/vite/bin/vite.js" ]; then
        echo "✅ vite.js文件存在"
        
        # 手动创建可执行文件链接
        echo "🔧 手动创建vite可执行文件链接..."
        mkdir -p node_modules/.bin
        ln -sf ../vite/bin/vite.js node_modules/.bin/vite
        chmod +x node_modules/.bin/vite
        
        if [ -f "node_modules/.bin/vite" ]; then
            echo "✅ vite可执行文件链接已创建"
        else
            echo "❌ vite可执行文件链接创建失败"
        fi
    else
        echo "❌ vite.js文件不存在"
    fi
else
    echo "❌ vite包未安装"
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

# 方法5: 尝试使用Vue CLI
if [ "$BUILD_SUCCESS" = false ]; then
    echo "尝试使用Vue CLI构建..."
    if [ -f "node_modules/.bin/vue-cli-service" ]; then
        ./node_modules/.bin/vue-cli-service build && BUILD_SUCCESS=true
    elif command -v npx >/dev/null 2>&1; then
        npx vue-cli-service build && BUILD_SUCCESS=true
    fi
fi

# 方法6: 强制重新安装并尝试
if [ "$BUILD_SUCCESS" = false ]; then
    echo "🔧 强制重新安装并尝试..."
    rm -rf node_modules package-lock.json
    npm install --force
    
    # 重新创建链接
    if [ -f "node_modules/vite/bin/vite.js" ]; then
        mkdir -p node_modules/.bin
        ln -sf ../vite/bin/vite.js node_modules/.bin/vite
        chmod +x node_modules/.bin/vite
        ./node_modules/.bin/vite build && BUILD_SUCCESS=true
    fi
fi

if [ "$BUILD_SUCCESS" = false ]; then
    echo "❌ 所有构建方法都失败了"
    echo "详细诊断信息："
    echo "=================================="
    echo "1. 检查package.json："
    cat package.json | grep -E '"vite"|"@vitejs/plugin-vue"'
    echo ""
    echo "2. 检查node_modules目录："
    ls -la node_modules/.bin/ 2>/dev/null || echo "node_modules/.bin目录不存在"
    echo ""
    echo "3. 检查vite包："
    ls -la node_modules/vite/ 2>/dev/null || echo "vite包不存在"
    echo ""
    echo "4. 检查vite.js文件："
    ls -la node_modules/vite/bin/ 2>/dev/null || echo "vite/bin目录不存在"
    echo ""
    echo "5. 尝试手动运行vite："
    if [ -f "node_modules/vite/bin/vite.js" ]; then
        node node_modules/vite/bin/vite.js --version || echo "vite无法运行"
    else
        echo "vite.js文件不存在"
    fi
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

echo "✅ Debian 11 构建修复完成！"
echo "访问地址: http://你的域名"
echo "查看状态: pm2 status"
