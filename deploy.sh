#!/bin/bash

# EZ-Theme Builder 部署脚本

echo "🚀 开始部署 EZ-Theme Builder..."

# 检查Node.js版本
echo "📋 检查Node.js版本..."
node_version=$(node -v)
echo "当前Node.js版本: $node_version"

# 安装依赖
echo "📦 安装依赖..."
npm install

# 构建前端
echo "🔨 构建前端..."
cd frontend
npm install
npm run build
cd ..

# 准备基础构建
echo "🏗️ 准备基础构建..."
npm run prepare-base

# 创建必要目录
echo "📁 创建必要目录..."
mkdir -p builds temp data

# 设置权限
echo "🔐 设置文件权限..."
chmod +x deploy.sh

# 启动应用
echo "🎯 启动应用..."
echo "应用将在 http://localhost:3000 启动"
echo "管理后台: http://localhost:3000/admin"
echo "默认管理员账户: admin / admin123"

npm start
