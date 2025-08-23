#!/bin/bash
# package.json 修复脚本
set -e

echo "🔧 package.json 修复脚本"

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用root用户运行此脚本"
    exit 1
fi

PROJECT_DIR="/www/wwwroot/ez-theme-builder"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 项目目录不存在: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

echo "📋 检查package.json文件..."

if [ ! -f "package.json" ]; then
    echo "❌ package.json文件不存在"
    exit 1
fi

# 备份原始文件
cp package.json package.json.backup.$(date +%Y%m%d_%H%M%S)

echo "✅ 已备份原始package.json文件"

# 检查JSON语法
echo "📋 检查JSON语法..."
if ! node -e "JSON.parse(require('fs').readFileSync('package.json', 'utf8'))" 2>/dev/null; then
    echo "❌ package.json有JSON语法错误"
    
    # 显示错误位置附近的内容
    echo "📋 错误位置附近的内容："
    head -c 650 package.json | tail -c 100
    echo ""
    
    # 尝试修复常见的JSON错误
    echo "🔧 尝试修复JSON语法错误..."
    
    # 修复1: 移除多余的逗号
    sed -i 's/,\s*}/}/g' package.json
    sed -i 's/,\s*]/]/g' package.json
    
    # 修复2: 确保引号正确
    sed -i 's/"/"/g' package.json
    
    # 修复3: 移除可能的注释
    sed -i '/^[[:space:]]*\/\//d' package.json
    sed -i '/^[[:space:]]*\/\*/,/\*\//d' package.json
    
    # 修复4: 修复可能的转义字符问题
    sed -i 's/\\"/"/g' package.json
    
    echo "✅ 已尝试修复JSON语法错误"
else
    echo "✅ package.json语法正确"
fi

# 再次检查JSON语法
echo "📋 再次检查JSON语法..."
if node -e "JSON.parse(require('fs').readFileSync('package.json', 'utf8'))" 2>/dev/null; then
    echo "✅ package.json语法修复成功"
else
    echo "❌ package.json语法仍有问题，尝试重新创建..."
    
    # 创建新的package.json
    cat > package.json << 'EOF'
{
  "name": "ez-theme-builder",
  "version": "1.0.0",
  "description": "EZ Theme Builder - 一键主题生成器",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "build": "npm run prepare-base && npm run build-frontend",
    "build-frontend": "cd frontend && npm run build",
    "prepare-base": "node prepare-base-build.js",
    "lightweight-build": "node lightweight-build.js",
    "safe-build": "node safe-build.js",
    "vercel-build": "node vercel-build.js"
  },
  "keywords": [
    "theme",
    "builder",
    "v2board",
    "v2ray",
    "shadowsocks",
    "trojan"
  ],
  "author": "EZ Theme Builder Team",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "multer": "^1.4.5-lts.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "compression": "^1.7.4",
    "jsonwebtoken": "^9.0.0",
    "bcryptjs": "^2.4.3",
    "sqlite3": "^5.1.6",
    "uuid": "^9.0.0",
    "archiver": "^6.0.1",
    "fs-extra": "^11.1.1",
    "path": "^0.12.7",
    "url": "^0.11.3",
    "querystring": "^0.2.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  },
  "engines": {
    "node": ">=16.0.0"
  }
}
EOF
    
    echo "✅ 已重新创建package.json文件"
fi

# 验证npm install
echo "📋 测试npm install..."
if npm install --dry-run >/dev/null 2>&1; then
    echo "✅ package.json修复成功，npm install测试通过"
else
    echo "❌ npm install测试失败"
    exit 1
fi

echo ""
echo "🎉 package.json修复完成！"
echo ""
echo "📋 修复内容："
echo "✅ 备份了原始package.json文件"
echo "✅ 修复了JSON语法错误"
echo "✅ 验证了npm install兼容性"
echo ""
echo "💡 现在可以重新运行Docker构建了！"
