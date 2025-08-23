#!/bin/bash
# IPv6 问题修复脚本
set -e

echo "🔧 IPv6 问题修复脚本"

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用root用户运行此脚本"
    exit 1
fi

echo "📋 检测网络配置..."

# 检查IPv6状态
if [ -f /proc/net/if_inet6 ]; then
    echo "✅ IPv6 已启用"
    echo "📋 IPv6 地址:"
    ip -6 addr show | grep inet6 | head -3
else
    echo "❌ IPv6 未启用"
fi

# 检查网络连接
echo "📋 测试网络连接..."

# 测试IPv4连接
if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
    echo "✅ IPv4 连接正常"
else
    echo "❌ IPv4 连接失败"
fi

# 测试IPv6连接
if ping6 -c 1 -W 3 2001:4860:4860::8888 >/dev/null 2>&1; then
    echo "✅ IPv6 连接正常"
else
    echo "❌ IPv6 连接失败"
fi

echo ""
echo "🔧 开始修复..."

# 方法1: 禁用IPv6
echo "📋 方法1: 禁用IPv6..."
echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf

# 应用配置
sysctl -p

echo "✅ IPv6 已禁用"

# 方法2: 更新软件源为IPv4
echo "📋 方法2: 更新软件源为IPv4..."

# 备份原始源文件
cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)

# 创建新的软件源文件（使用IPv4）
cat > /etc/apt/sources.list << 'EOF'
# Debian 11 (Bullseye) 软件源 - IPv4
deb http://151.101.0.204/debian bullseye main contrib non-free
deb http://151.101.0.204/debian bullseye-updates main contrib non-free
deb http://151.101.0.204/debian-security bullseye-security main contrib non-free
EOF

echo "✅ 软件源已更新为IPv4"

# 清理apt缓存
echo "📋 清理apt缓存..."
apt-get clean
apt-get autoclean

# 测试更新
echo "📋 测试软件包更新..."
apt-get update

if [ $? -eq 0 ]; then
    echo "✅ 软件包更新成功！"
else
    echo "❌ IPv4源也失败了，尝试使用国内镜像..."
    
    # 使用阿里云镜像源
    cat > /etc/apt/sources.list << 'EOF'
# Debian 11 (Bullseye) 阿里云镜像源
deb http://mirrors.aliyun.com/debian/ bullseye main contrib non-free
deb http://mirrors.aliyun.com/debian/ bullseye-updates main contrib non-free
deb http://mirrors.aliyun.com/debian-security/ bullseye-security main contrib non-free
EOF
    
    apt-get update
    
    if [ $? -eq 0 ]; then
        echo "✅ 阿里云镜像源更新成功！"
    else
        echo "❌ 所有源都失败了"
        echo "📋 恢复原始源文件..."
        cp /etc/apt/sources.list.backup.* /etc/apt/sources.list
        exit 1
    fi
fi

# 升级系统
echo "📋 升级系统软件包..."
apt-get upgrade -y

echo ""
echo "🎉 IPv6 问题修复完成！"
echo ""
echo "📋 修复内容："
echo "✅ 禁用了IPv6"
echo "✅ 更新软件源为IPv4"
echo "✅ 清理了apt缓存"
echo "✅ 更新了软件包列表"
echo "✅ 升级了系统软件包"
echo ""
echo "💡 现在可以继续安装Docker了！"
echo "运行: wget -O deploy-docker.sh https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/deploy-docker.sh && chmod +x deploy-docker.sh && ./deploy-docker.sh"
# IPv6 问题修复脚本
set -e

echo "🔧 IPv6 问题修复脚本"

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用root用户运行此脚本"
    exit 1
fi

echo "📋 检测网络配置..."

# 检查IPv6状态
if [ -f /proc/net/if_inet6 ]; then
    echo "✅ IPv6 已启用"
    echo "📋 IPv6 地址:"
    ip -6 addr show | grep inet6 | head -3
else
    echo "❌ IPv6 未启用"
fi

# 检查网络连接
echo "📋 测试网络连接..."

# 测试IPv4连接
if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
    echo "✅ IPv4 连接正常"
else
    echo "❌ IPv4 连接失败"
fi

# 测试IPv6连接
if ping6 -c 1 -W 3 2001:4860:4860::8888 >/dev/null 2>&1; then
    echo "✅ IPv6 连接正常"
else
    echo "❌ IPv6 连接失败"
fi

echo ""
echo "🔧 开始修复..."

# 方法1: 禁用IPv6
echo "📋 方法1: 禁用IPv6..."
echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf

# 应用配置
sysctl -p

echo "✅ IPv6 已禁用"

# 方法2: 更新软件源为IPv4
echo "📋 方法2: 更新软件源为IPv4..."

# 备份原始源文件
cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)

# 创建新的软件源文件（使用IPv4）
cat > /etc/apt/sources.list << 'EOF'
# Debian 11 (Bullseye) 软件源 - IPv4
deb http://151.101.0.204/debian bullseye main contrib non-free
deb http://151.101.0.204/debian bullseye-updates main contrib non-free
deb http://151.101.0.204/debian-security bullseye-security main contrib non-free
EOF

echo "✅ 软件源已更新为IPv4"

# 清理apt缓存
echo "📋 清理apt缓存..."
apt-get clean
apt-get autoclean

# 测试更新
echo "📋 测试软件包更新..."
apt-get update

if [ $? -eq 0 ]; then
    echo "✅ 软件包更新成功！"
else
    echo "❌ IPv4源也失败了，尝试使用国内镜像..."
    
    # 使用阿里云镜像源
    cat > /etc/apt/sources.list << 'EOF'
# Debian 11 (Bullseye) 阿里云镜像源
deb http://mirrors.aliyun.com/debian/ bullseye main contrib non-free
deb http://mirrors.aliyun.com/debian/ bullseye-updates main contrib non-free
deb http://mirrors.aliyun.com/debian-security/ bullseye-security main contrib non-free
EOF
    
    apt-get update
    
    if [ $? -eq 0 ]; then
        echo "✅ 阿里云镜像源更新成功！"
    else
        echo "❌ 所有源都失败了"
        echo "📋 恢复原始源文件..."
        cp /etc/apt/sources.list.backup.* /etc/apt/sources.list
        exit 1
    fi
fi

# 升级系统
echo "📋 升级系统软件包..."
apt-get upgrade -y

echo ""
echo "🎉 IPv6 问题修复完成！"
echo ""
echo "📋 修复内容："
echo "✅ 禁用了IPv6"
echo "✅ 更新软件源为IPv4"
echo "✅ 清理了apt缓存"
echo "✅ 更新了软件包列表"
echo "✅ 升级了系统软件包"
echo ""
echo "💡 现在可以继续安装Docker了！"
echo "运行: wget -O deploy-docker.sh https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/deploy-docker.sh && chmod +x deploy-docker.sh && ./deploy-docker.sh"
