#!/bin/bash
# Debian 软件源修复脚本
set -e

echo "🔧 Debian 软件源修复脚本"

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用root用户运行此脚本"
    exit 1
fi

# 检查是否为Debian系统
if [ ! -f /etc/debian_version ]; then
    echo "❌ 此脚本仅适用于Debian系统"
    exit 1
fi

echo "📋 系统信息: $(cat /etc/os-release | grep PRETTY_NAME)"

# 备份原始源文件
echo "📋 备份原始软件源文件..."
cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ 备份完成: /etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)"

# 创建新的软件源文件
echo "📋 创建新的软件源文件..."
cat > /etc/apt/sources.list << 'EOF'
# Debian 11 (Bullseye) 软件源
# 主仓库
deb http://deb.debian.org/debian bullseye main contrib non-free
deb-src http://deb.debian.org/debian bullseye main contrib non-free

# 安全更新
deb http://security.debian.org/debian-security bullseye-security main contrib non-free
deb-src http://security.debian.org/debian-security bullseye-security main contrib non-free

# 系统更新
deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free
EOF

echo "✅ 新的软件源文件已创建"

# 清理apt缓存
echo "📋 清理apt缓存..."
apt-get clean
apt-get autoclean

# 更新软件包列表
echo "📋 更新软件包列表..."
apt-get update

if [ $? -eq 0 ]; then
    echo "✅ 软件包列表更新成功"
else
    echo "❌ 软件包列表更新失败"
    echo "📋 尝试使用备用源..."
    
    # 备用源
    cat > /etc/apt/sources.list << 'EOF'
# Debian 11 (Bullseye) 备用软件源
deb http://mirrors.aliyun.com/debian/ bullseye main contrib non-free
deb-src http://mirrors.aliyun.com/debian/ bullseye main contrib non-free

deb http://mirrors.aliyun.com/debian-security/ bullseye-security main contrib non-free
deb-src http://mirrors.aliyun.com/debian-security/ bullseye-security main contrib non-free

deb http://mirrors.aliyun.com/debian/ bullseye-updates main contrib non-free
deb-src http://mirrors.aliyun.com/debian/ bullseye-updates main contrib non-free
EOF
    
    apt-get update
    
    if [ $? -eq 0 ]; then
        echo "✅ 备用源更新成功"
    else
        echo "❌ 备用源也失败了"
        echo "📋 恢复原始源文件..."
        cp /etc/apt/sources.list.backup.* /etc/apt/sources.list
        exit 1
    fi
fi

# 升级系统
echo "📋 升级系统软件包..."
apt-get upgrade -y

echo ""
echo "🎉 Debian软件源修复完成！"
echo ""
echo "📋 修复内容："
echo "✅ 移除了不存在的bullseye-backports仓库"
echo "✅ 更新了软件源配置"
echo "✅ 清理了apt缓存"
echo "✅ 更新了软件包列表"
echo "✅ 升级了系统软件包"
echo ""
echo "�� 现在可以继续安装Docker了！"
