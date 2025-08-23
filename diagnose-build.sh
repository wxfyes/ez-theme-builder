#!/bin/bash
# EZ-Theme Builder 构建问题诊断脚本
set -e

echo "🔍 构建问题诊断脚本..."

PROJECT_DIR="/www/wwwroot/ez-theme-builder"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 项目目录不存在: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR/frontend"

echo "📋 诊断信息："
echo "=================================="

echo "1. 检查package.json中的构建工具依赖："
echo "----------------------------------"
grep -E '"vite"|"@vue/cli-service"' package.json || echo "未找到构建工具依赖"

echo ""
echo "2. 检查node_modules/.bin目录："
echo "----------------------------------"
if [ -d "node_modules/.bin" ]; then
    ls -la node_modules/.bin/ | grep -E "vite|vue-cli" || echo "没有找到vite或vue-cli相关文件"
else
    echo "node_modules/.bin目录不存在"
fi

echo ""
echo "3. 检查vite包安装情况："
echo "----------------------------------"
if [ -d "node_modules/vite" ]; then
    echo "✅ vite包已安装"
    ls -la node_modules/vite/bin/ 2>/dev/null || echo "vite/bin目录不存在"
    if [ -f "node_modules/vite/bin/vite.js" ]; then
        echo "✅ vite.js文件存在"
    else
        echo "❌ vite.js文件不存在"
    fi
else
    echo "❌ vite包未安装"
fi

echo ""
echo "4. 检查vue-cli-service包安装情况："
echo "----------------------------------"
if [ -d "node_modules/@vue/cli-service" ]; then
    echo "✅ @vue/cli-service包已安装"
    ls -la node_modules/@vue/cli-service/bin/ 2>/dev/null || echo "@vue/cli-service/bin目录不存在"
    if [ -f "node_modules/@vue/cli-service/bin/vue-cli-service.js" ]; then
        echo "✅ vue-cli-service.js文件存在"
    else
        echo "❌ vue-cli-service.js文件不存在"
    fi
else
    echo "❌ @vue/cli-service包未安装"
fi

echo ""
echo "5. 检查npm版本和配置："
echo "----------------------------------"
npm --version
echo "npm配置："
npm config list | grep -E "bin|prefix" || echo "无相关配置"

echo ""
echo "6. 尝试修复建议："
echo "----------------------------------"

# 检查是否需要重新安装
if [ ! -f "node_modules/.bin/vite" ] && [ -d "node_modules/vite" ]; then
    echo "🔧 发现vite包已安装但缺少可执行文件链接"
    echo "建议执行：npm rebuild vite"
fi

if [ ! -f "node_modules/.bin/vue-cli-service" ] && [ -d "node_modules/@vue/cli-service" ]; then
    echo "🔧 发现@vue/cli-service包已安装但缺少可执行文件链接"
    echo "建议执行：npm rebuild @vue/cli-service"
fi

if [ ! -d "node_modules/vite" ] && [ ! -d "node_modules/@vue/cli-service" ]; then
    echo "🔧 未发现任何构建工具包"
    echo "建议执行：npm install"
fi

echo ""
echo "7. 快速修复命令："
echo "----------------------------------"
echo "如果诊断发现问题，可以运行以下命令："
echo ""
echo "# 方法1：重新安装所有依赖"
echo "rm -rf node_modules package-lock.json && npm install"
echo ""
echo "# 方法2：重建npm链接"
echo "npm rebuild"
echo ""
echo "# 方法3：使用终极修复脚本"
echo "wget -O quick-fix-ultimate.sh https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/quick-fix-ultimate.sh && chmod +x quick-fix-ultimate.sh && ./quick-fix-ultimate.sh"
echo ""
echo "=================================="
echo "诊断完成！"
