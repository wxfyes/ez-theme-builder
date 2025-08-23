#!/bin/bash
# Docker 仓库修复脚本
set -e

echo "🔧 Docker 仓库修复脚本"

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用root用户运行此脚本"
    exit 1
fi

echo "📋 检测系统信息..."
echo "系统: $(cat /etc/os-release | grep PRETTY_NAME)"
echo "版本: $(lsb_release -cs)"

echo ""
echo "🔧 开始修复 Docker 仓库..."

# 1. 删除错误的 Docker 仓库配置
echo "📋 步骤1: 删除错误的 Docker 仓库配置..."
rm -f /etc/apt/sources.list.d/docker.list
echo "✅ 错误的仓库配置已删除"

# 2. 添加正确的 Debian Docker 仓库
echo "📋 步骤2: 添加正确的 Debian Docker 仓库..."

# 下载 Docker 官方 GPG 密钥
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 添加 Docker 仓库
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "✅ 正确的 Docker 仓库已添加"

# 3. 更新软件包列表
echo "📋 步骤3: 更新软件包列表..."
apt-get update

if [ $? -eq 0 ]; then
    echo "✅ 软件包列表更新成功"
else
    echo "❌ 软件包列表更新失败"
    exit 1
fi

# 4. 安装 Docker
echo "📋 步骤4: 安装 Docker..."
apt-get install -y docker-ce docker-ce-cli containerd.io

if [ $? -eq 0 ]; then
    echo "✅ Docker 安装成功"
else
    echo "❌ Docker 安装失败"
    exit 1
fi

# 5. 启动 Docker 服务
echo "📋 步骤5: 启动 Docker 服务..."
systemctl start docker
systemctl enable docker

echo "✅ Docker 服务已启动"

# 6. 安装 Docker Compose
echo "📋 步骤6: 安装 Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "✅ Docker Compose 安装成功"

# 7. 验证安装
echo "📋 步骤7: 验证安装..."
echo ""
echo "🔍 Docker 版本:"
docker --version

echo ""
echo "🔍 Docker Compose 版本:"
docker-compose --version

echo ""
echo "🔍 Docker 服务状态:"
systemctl is-active docker

echo ""
echo "🎉 Docker 仓库修复完成！"
echo ""
echo "📋 修复内容："
echo "✅ 删除了错误的 Ubuntu 仓库配置"
echo "✅ 添加了正确的 Debian Docker 仓库"
echo "✅ 安装了 Docker CE"
echo "✅ 安装了 Docker Compose"
echo "✅ 启动了 Docker 服务"
echo ""
echo "💡 现在可以继续部署 EZ-Theme Builder 了！"
# Docker 仓库修复脚本
set -e

echo "🔧 Docker 仓库修复脚本"

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用root用户运行此脚本"
    exit 1
fi

echo "📋 检测系统信息..."
echo "系统: $(cat /etc/os-release | grep PRETTY_NAME)"
echo "版本: $(lsb_release -cs)"

echo ""
echo "🔧 开始修复 Docker 仓库..."

# 1. 删除错误的 Docker 仓库配置
echo "📋 步骤1: 删除错误的 Docker 仓库配置..."
rm -f /etc/apt/sources.list.d/docker.list
echo "✅ 错误的仓库配置已删除"

# 2. 添加正确的 Debian Docker 仓库
echo "📋 步骤2: 添加正确的 Debian Docker 仓库..."

# 下载 Docker 官方 GPG 密钥
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 添加 Docker 仓库
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "✅ 正确的 Docker 仓库已添加"

# 3. 更新软件包列表
echo "📋 步骤3: 更新软件包列表..."
apt-get update

if [ $? -eq 0 ]; then
    echo "✅ 软件包列表更新成功"
else
    echo "❌ 软件包列表更新失败"
    exit 1
fi

# 4. 安装 Docker
echo "📋 步骤4: 安装 Docker..."
apt-get install -y docker-ce docker-ce-cli containerd.io

if [ $? -eq 0 ]; then
    echo "✅ Docker 安装成功"
else
    echo "❌ Docker 安装失败"
    exit 1
fi

# 5. 启动 Docker 服务
echo "📋 步骤5: 启动 Docker 服务..."
systemctl start docker
systemctl enable docker

echo "✅ Docker 服务已启动"

# 6. 安装 Docker Compose
echo "📋 步骤6: 安装 Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "✅ Docker Compose 安装成功"

# 7. 验证安装
echo "📋 步骤7: 验证安装..."
echo ""
echo "🔍 Docker 版本:"
docker --version

echo ""
echo "🔍 Docker Compose 版本:"
docker-compose --version

echo ""
echo "🔍 Docker 服务状态:"
systemctl is-active docker

echo ""
echo "🎉 Docker 仓库修复完成！"
echo ""
echo "📋 修复内容："
echo "✅ 删除了错误的 Ubuntu 仓库配置"
echo "✅ 添加了正确的 Debian Docker 仓库"
echo "✅ 安装了 Docker CE"
echo "✅ 安装了 Docker Compose"
echo "✅ 启动了 Docker 服务"
echo ""
echo "💡 现在可以继续部署 EZ-Theme Builder 了！"
