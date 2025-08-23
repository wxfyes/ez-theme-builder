#!/bin/bash
# EZ-Theme Builder 完整安装脚本
set -e

echo "🚀 EZ-Theme Builder 完整安装脚本"
echo "📋 此脚本将自动处理所有已知问题并完成部署"

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用root用户运行此脚本"
    exit 1
fi

# 检查系统类型
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    echo "❌ 无法检测操作系统"
    exit 1
fi

echo "📋 系统信息: $OS $VER"

# 修复Debian软件源
fix_debian_sources() {
    echo "🔧 修复Debian软件源..."
    
    # 备份原始源文件
    cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)
    
    # 创建新的软件源文件
    cat > /etc/apt/sources.list << 'EOF'
# Debian 11 (Bullseye) 软件源
deb http://deb.debian.org/debian bullseye main contrib non-free
deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb http://security.debian.org/debian-security bullseye-security main contrib non-free
EOF
    
    echo "✅ Debian软件源已修复"
}

# 安装Docker
install_docker() {
    echo "🔧 安装Docker..."
    
    if command -v docker &> /dev/null; then
        echo "✅ Docker已安装"
        docker --version
        return 0
    fi
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            echo "📦 在Ubuntu/Debian上安装Docker..."
            
            # 修复Debian软件源
            if [[ "$OS" == *"Debian"* ]]; then
                fix_debian_sources
            fi
            
            # 更新包列表
            apt-get update
            
            # 安装依赖
            apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            
            # 删除可能存在的错误Docker仓库
            rm -f /etc/apt/sources.list.d/docker.list
            
            # 添加Docker官方GPG密钥
            curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # 添加Docker仓库
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # 安装Docker
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io
            ;;
        *"CentOS"*|*"Red Hat"*)
            echo "📦 在CentOS/Red Hat上安装Docker..."
            yum install -y yum-utils
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            yum install -y docker-ce docker-ce-cli containerd.io
            ;;
        *)
            echo "❌ 不支持的操作系统: $OS"
            exit 1
            ;;
    esac
    
    # 启动Docker服务
    systemctl start docker
    systemctl enable docker
    
    echo "✅ Docker安装完成"
    docker --version
}

# 安装Docker Compose
install_docker_compose() {
    echo "🔧 安装Docker Compose..."
    
    if command -v docker-compose &> /dev/null; then
        echo "✅ Docker Compose已安装"
        docker-compose --version
        return 0
    fi
    
    # 下载Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    echo "✅ Docker Compose安装完成"
    docker-compose --version
}

# 创建项目目录
create_project_dir() {
    echo "📁 创建项目目录..."
    PROJECT_DIR="/www/wwwroot/ez-theme-builder"
    
    if [ ! -d "$PROJECT_DIR" ]; then
        mkdir -p "$PROJECT_DIR"
    fi
    
    cd "$PROJECT_DIR"
    echo "✅ 项目目录: $PROJECT_DIR"
}

# 下载项目文件
download_project() {
    echo "📥 下载项目文件..."
    
    # 检查是否已有项目文件
    if [ -f "package.json" ]; then
        echo "✅ 项目文件已存在"
        return 0
    fi
    
    # 下载项目
    wget -O ez-theme-builder.zip https://github.com/wxfyes/ez-theme-builder/archive/refs/heads/main.zip
    
    if [ ! -f "ez-theme-builder.zip" ]; then
        echo "❌ 下载失败"
        exit 1
    fi
    
    # 解压文件
    unzip -o ez-theme-builder.zip
    mv ez-theme-builder-main/* .
    mv ez-theme-builder-main/.* . 2>/dev/null || true
    rmdir ez-theme-builder-main
    rm ez-theme-builder.zip
    
    echo "✅ 项目文件下载完成"
}

# 修复package.json
fix_package_json() {
    echo "🔧 修复package.json..."
    
    # 备份package.json
    cp package.json package.json.backup
    
    # 移除postinstall脚本
    sed -i '/"postinstall"/d' package.json
    sed -i '/"npm run prepare-base"/d' package.json
    
    echo "✅ package.json已修复"
}

# 创建简化的Dockerfile
create_simple_dockerfile() {
    echo "📝 创建简化的Dockerfile..."
    
    cat > Dockerfile.simple << 'EOF'
# 使用官方Node.js 18镜像作为基础镜像
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apk add --no-cache \
    git \
    python3 \
    make \
    g++ \
    wget \
    curl

# 复制所有源代码
COPY . .

# 安装后端依赖（跳过postinstall脚本）
RUN npm ci --only=production --ignore-scripts

# 安装前端依赖
WORKDIR /app/frontend
RUN npm ci --only=production

# 构建前端
RUN npm run build

# 回到根目录
WORKDIR /app

# 创建必要的目录
RUN mkdir -p logs builds temp data

# 暴露端口
EXPOSE 3000

# 设置环境变量
ENV NODE_ENV=production
ENV NODE_OPTIONS=--max-old-space-size=512
ENV PORT=3000

# 启动命令
CMD ["node", "server.js"]
EOF

    echo "✅ 简化的Dockerfile已创建"
}

# 创建docker-compose.yml
create_docker_compose() {
    echo "📝 创建docker-compose.yml..."
    
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  ez-theme-builder:
    build:
      context: .
      dockerfile: Dockerfile.simple
    container_name: ez-theme-builder
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - NODE_OPTIONS=--max-old-space-size=512
      - PORT=3000
      - JWT_SECRET=your-secret-key-here
    volumes:
      - ./logs:/app/logs
      - ./builds:/app/builds
      - ./temp:/app/temp
      - ./data:/app/data
    networks:
      - ez-theme-network

networks:
  ez-theme-network:
    driver: bridge
EOF

    echo "✅ docker-compose.yml已创建"
}

# 构建和运行Docker容器
build_and_run() {
    echo "🔨 构建Docker镜像..."
    
    # 清理之前的构建
    docker-compose down 2>/dev/null || true
    docker system prune -f
    
    # 构建镜像
    docker-compose build --no-cache
    
    if [ $? -ne 0 ]; then
        echo "❌ Docker镜像构建失败"
        exit 1
    fi
    
    echo "✅ Docker镜像构建完成"
    
    echo "🚀 启动容器..."
    docker-compose up -d
    
    if [ $? -ne 0 ]; then
        echo "❌ 容器启动失败"
        exit 1
    fi
    
    echo "✅ 容器启动完成"
}

# 检查容器状态
check_status() {
    echo "📊 检查容器状态..."
    sleep 10
    
    if docker-compose ps | grep -q "Up"; then
        echo "✅ 容器运行正常"
        echo "🌐 访问地址: http://$(hostname -I | awk '{print $1}'):3000"
        echo "🔧 管理地址: http://$(hostname -I | awk '{print $1}'):3000/admin"
    else
        echo "❌ 容器启动失败"
        echo "📋 查看日志:"
        docker-compose logs
        exit 1
    fi
}

# 创建管理脚本
create_management_scripts() {
    echo "📝 创建管理脚本..."
    
    # 启动脚本
    cat > start.sh << 'EOF'
#!/bin/bash
cd /www/wwwroot/ez-theme-builder
docker-compose up -d
echo "✅ 应用已启动"
EOF
    
    # 停止脚本
    cat > stop.sh << 'EOF'
#!/bin/bash
cd /www/wwwroot/ez-theme-builder
docker-compose down
echo "✅ 应用已停止"
EOF
    
    # 重启脚本
    cat > restart.sh << 'EOF'
#!/bin/bash
cd /www/wwwroot/ez-theme-builder
docker-compose restart
echo "✅ 应用已重启"
EOF
    
    # 日志脚本
    cat > logs.sh << 'EOF'
#!/bin/bash
cd /www/wwwroot/ez-theme-builder
docker-compose logs -f
EOF
    
    # 更新脚本
    cat > update.sh << 'EOF'
#!/bin/bash
cd /www/wwwroot/ez-theme-builder
docker-compose down
docker-compose build --no-cache
docker-compose up -d
echo "✅ 应用已更新"
EOF
    
    # 删除脚本
    cat > remove.sh << 'EOF'
#!/bin/bash
cd /www/wwwroot/ez-theme-builder
docker-compose down
docker system prune -f
rm -rf /www/wwwroot/ez-theme-builder
echo "✅ 应用已完全删除"
EOF
    
    # 设置执行权限
    chmod +x start.sh stop.sh restart.sh logs.sh update.sh remove.sh
    
    echo "✅ 管理脚本创建完成"
}

# 显示使用说明
show_usage() {
    echo ""
    echo "🎉 安装完成！"
    echo ""
    echo "📋 管理命令："
    echo "  启动应用: ./start.sh"
    echo "  停止应用: ./stop.sh"
    echo "  重启应用: ./restart.sh"
    echo "  查看日志: ./logs.sh"
    echo "  更新应用: ./update.sh"
    echo "  删除应用: ./remove.sh"
    echo ""
    echo "🌐 访问地址："
    echo "  用户界面: http://$(hostname -I | awk '{print $1}'):3000"
    echo "  管理后台: http://$(hostname -I | awk '{print $1}'):3000/admin"
    echo ""
    echo "📊 查看状态："
    echo "  docker-compose ps"
    echo "  docker-compose logs"
    echo ""
    echo "🔧 故障排除："
    echo "  如果容器启动失败，请运行: ./logs.sh 查看详细日志"
}

# 主函数
main() {
    echo "🚀 开始完整安装..."
    
    install_docker
    install_docker_compose
    create_project_dir
    download_project
    fix_package_json
    create_simple_dockerfile
    create_docker_compose
    build_and_run
    check_status
    create_management_scripts
    show_usage
}

# 运行主函数
main
# EZ-Theme Builder 完整安装脚本
set -e

echo "🚀 EZ-Theme Builder 完整安装脚本"
echo "📋 此脚本将自动处理所有已知问题并完成部署"

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用root用户运行此脚本"
    exit 1
fi

# 检查系统类型
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    echo "❌ 无法检测操作系统"
    exit 1
fi

echo "📋 系统信息: $OS $VER"

# 修复Debian软件源
fix_debian_sources() {
    echo "🔧 修复Debian软件源..."
    
    # 备份原始源文件
    cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)
    
    # 创建新的软件源文件
    cat > /etc/apt/sources.list << 'EOF'
# Debian 11 (Bullseye) 软件源
deb http://deb.debian.org/debian bullseye main contrib non-free
deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb http://security.debian.org/debian-security bullseye-security main contrib non-free
EOF
    
    echo "✅ Debian软件源已修复"
}

# 安装Docker
install_docker() {
    echo "🔧 安装Docker..."
    
    if command -v docker &> /dev/null; then
        echo "✅ Docker已安装"
        docker --version
        return 0
    fi
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            echo "📦 在Ubuntu/Debian上安装Docker..."
            
            # 修复Debian软件源
            if [[ "$OS" == *"Debian"* ]]; then
                fix_debian_sources
            fi
            
            # 更新包列表
            apt-get update
            
            # 安装依赖
            apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            
            # 删除可能存在的错误Docker仓库
            rm -f /etc/apt/sources.list.d/docker.list
            
            # 添加Docker官方GPG密钥
            curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # 添加Docker仓库
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # 安装Docker
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io
            ;;
        *"CentOS"*|*"Red Hat"*)
            echo "📦 在CentOS/Red Hat上安装Docker..."
            yum install -y yum-utils
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            yum install -y docker-ce docker-ce-cli containerd.io
            ;;
        *)
            echo "❌ 不支持的操作系统: $OS"
            exit 1
            ;;
    esac
    
    # 启动Docker服务
    systemctl start docker
    systemctl enable docker
    
    echo "✅ Docker安装完成"
    docker --version
}

# 安装Docker Compose
install_docker_compose() {
    echo "🔧 安装Docker Compose..."
    
    if command -v docker-compose &> /dev/null; then
        echo "✅ Docker Compose已安装"
        docker-compose --version
        return 0
    fi
    
    # 下载Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    echo "✅ Docker Compose安装完成"
    docker-compose --version
}

# 创建项目目录
create_project_dir() {
    echo "📁 创建项目目录..."
    PROJECT_DIR="/www/wwwroot/ez-theme-builder"
    
    if [ ! -d "$PROJECT_DIR" ]; then
        mkdir -p "$PROJECT_DIR"
    fi
    
    cd "$PROJECT_DIR"
    echo "✅ 项目目录: $PROJECT_DIR"
}

# 下载项目文件
download_project() {
    echo "📥 下载项目文件..."
    
    # 检查是否已有项目文件
    if [ -f "package.json" ]; then
        echo "✅ 项目文件已存在"
        return 0
    fi
    
    # 下载项目
    wget -O ez-theme-builder.zip https://github.com/wxfyes/ez-theme-builder/archive/refs/heads/main.zip
    
    if [ ! -f "ez-theme-builder.zip" ]; then
        echo "❌ 下载失败"
        exit 1
    fi
    
    # 解压文件
    unzip -o ez-theme-builder.zip
    mv ez-theme-builder-main/* .
    mv ez-theme-builder-main/.* . 2>/dev/null || true
    rmdir ez-theme-builder-main
    rm ez-theme-builder.zip
    
    echo "✅ 项目文件下载完成"
}

# 修复package.json
fix_package_json() {
    echo "🔧 修复package.json..."
    
    # 备份package.json
    cp package.json package.json.backup
    
    # 移除postinstall脚本
    sed -i '/"postinstall"/d' package.json
    sed -i '/"npm run prepare-base"/d' package.json
    
    echo "✅ package.json已修复"
}

# 创建简化的Dockerfile
create_simple_dockerfile() {
    echo "📝 创建简化的Dockerfile..."
    
    cat > Dockerfile.simple << 'EOF'
# 使用官方Node.js 18镜像作为基础镜像
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apk add --no-cache \
    git \
    python3 \
    make \
    g++ \
    wget \
    curl

# 复制所有源代码
COPY . .

# 安装后端依赖（跳过postinstall脚本）
RUN npm ci --only=production --ignore-scripts

# 安装前端依赖
WORKDIR /app/frontend
RUN npm ci --only=production

# 构建前端
RUN npm run build

# 回到根目录
WORKDIR /app

# 创建必要的目录
RUN mkdir -p logs builds temp data

# 暴露端口
EXPOSE 3000

# 设置环境变量
ENV NODE_ENV=production
ENV NODE_OPTIONS=--max-old-space-size=512
ENV PORT=3000

# 启动命令
CMD ["node", "server.js"]
EOF

    echo "✅ 简化的Dockerfile已创建"
}

# 创建docker-compose.yml
create_docker_compose() {
    echo "📝 创建docker-compose.yml..."
    
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  ez-theme-builder:
    build:
      context: .
      dockerfile: Dockerfile.simple
    container_name: ez-theme-builder
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - NODE_OPTIONS=--max-old-space-size=512
      - PORT=3000
      - JWT_SECRET=your-secret-key-here
    volumes:
      - ./logs:/app/logs
      - ./builds:/app/builds
      - ./temp:/app/temp
      - ./data:/app/data
    networks:
      - ez-theme-network

networks:
  ez-theme-network:
    driver: bridge
EOF

    echo "✅ docker-compose.yml已创建"
}

# 构建和运行Docker容器
build_and_run() {
    echo "🔨 构建Docker镜像..."
    
    # 清理之前的构建
    docker-compose down 2>/dev/null || true
    docker system prune -f
    
    # 构建镜像
    docker-compose build --no-cache
    
    if [ $? -ne 0 ]; then
        echo "❌ Docker镜像构建失败"
        exit 1
    fi
    
    echo "✅ Docker镜像构建完成"
    
    echo "🚀 启动容器..."
    docker-compose up -d
    
    if [ $? -ne 0 ]; then
        echo "❌ 容器启动失败"
        exit 1
    fi
    
    echo "✅ 容器启动完成"
}

# 检查容器状态
check_status() {
    echo "📊 检查容器状态..."
    sleep 10
    
    if docker-compose ps | grep -q "Up"; then
        echo "✅ 容器运行正常"
        echo "🌐 访问地址: http://$(hostname -I | awk '{print $1}'):3000"
        echo "🔧 管理地址: http://$(hostname -I | awk '{print $1}'):3000/admin"
    else
        echo "❌ 容器启动失败"
        echo "📋 查看日志:"
        docker-compose logs
        exit 1
    fi
}

# 创建管理脚本
create_management_scripts() {
    echo "📝 创建管理脚本..."
    
    # 启动脚本
    cat > start.sh << 'EOF'
#!/bin/bash
cd /www/wwwroot/ez-theme-builder
docker-compose up -d
echo "✅ 应用已启动"
EOF
    
    # 停止脚本
    cat > stop.sh << 'EOF'
#!/bin/bash
cd /www/wwwroot/ez-theme-builder
docker-compose down
echo "✅ 应用已停止"
EOF
    
    # 重启脚本
    cat > restart.sh << 'EOF'
#!/bin/bash
cd /www/wwwroot/ez-theme-builder
docker-compose restart
echo "✅ 应用已重启"
EOF
    
    # 日志脚本
    cat > logs.sh << 'EOF'
#!/bin/bash
cd /www/wwwroot/ez-theme-builder
docker-compose logs -f
EOF
    
    # 更新脚本
    cat > update.sh << 'EOF'
#!/bin/bash
cd /www/wwwroot/ez-theme-builder
docker-compose down
docker-compose build --no-cache
docker-compose up -d
echo "✅ 应用已更新"
EOF
    
    # 删除脚本
    cat > remove.sh << 'EOF'
#!/bin/bash
cd /www/wwwroot/ez-theme-builder
docker-compose down
docker system prune -f
rm -rf /www/wwwroot/ez-theme-builder
echo "✅ 应用已完全删除"
EOF
    
    # 设置执行权限
    chmod +x start.sh stop.sh restart.sh logs.sh update.sh remove.sh
    
    echo "✅ 管理脚本创建完成"
}

# 显示使用说明
show_usage() {
    echo ""
    echo "🎉 安装完成！"
    echo ""
    echo "📋 管理命令："
    echo "  启动应用: ./start.sh"
    echo "  停止应用: ./stop.sh"
    echo "  重启应用: ./restart.sh"
    echo "  查看日志: ./logs.sh"
    echo "  更新应用: ./update.sh"
    echo "  删除应用: ./remove.sh"
    echo ""
    echo "🌐 访问地址："
    echo "  用户界面: http://$(hostname -I | awk '{print $1}'):3000"
    echo "  管理后台: http://$(hostname -I | awk '{print $1}'):3000/admin"
    echo ""
    echo "📊 查看状态："
    echo "  docker-compose ps"
    echo "  docker-compose logs"
    echo ""
    echo "🔧 故障排除："
    echo "  如果容器启动失败，请运行: ./logs.sh 查看详细日志"
}

# 主函数
main() {
    echo "🚀 开始完整安装..."
    
    install_docker
    install_docker_compose
    create_project_dir
    download_project
    fix_package_json
    create_simple_dockerfile
    create_docker_compose
    build_and_run
    check_status
    create_management_scripts
    show_usage
}

# 运行主函数
main
