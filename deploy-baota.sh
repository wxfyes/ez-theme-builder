#!/bin/bash

# EZ-Theme Builder 宝塔面板部署脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用root用户运行此脚本"
        exit 1
    fi
}

# 检查宝塔面板
check_baota() {
    if [ ! -f "/etc/init.d/bt" ]; then
        log_error "未检测到宝塔面板，请先安装宝塔面板"
        log_info "安装命令：wget -O install.sh http://download.bt.cn/install/install_6.0.sh && sh install.sh"
        exit 1
    fi
    log_success "检测到宝塔面板"
}

# 检查Node.js
check_nodejs() {
    if ! command -v node &> /dev/null; then
        log_error "Node.js未安装，请在宝塔面板中安装Node.js版本管理器"
        exit 1
    fi
    NODE_VERSION=$(node --version)
    log_success "Node.js已安装: $NODE_VERSION"
}

# 设置项目目录
setup_project() {
    PROJECT_DIR="/www/wwwroot/ez-theme-builder"
    
    log_info "设置项目目录: $PROJECT_DIR"
    
    # 创建项目目录
    mkdir -p $PROJECT_DIR
    cd $PROJECT_DIR
    
    # 如果目录为空，克隆项目
    if [ ! "$(ls -A)" ]; then
        log_info "克隆项目..."
        git clone https://github.com/wxfyes/ez-theme-builder.git .
    else
        log_info "项目已存在，更新代码..."
        git pull origin main
    fi
    
    log_success "项目设置完成"
}

# 设置环境变量
setup_environment() {
    log_info "设置环境变量..."
    
    # 检测内存大小
    TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    
    if [ "$TOTAL_MEM" -lt 1024 ]; then
        NODE_OPTIONS="--max-old-space-size=256"
        log_warning "检测到内存较小 ($TOTAL_MEM MB)，使用 256MB 内存限制"
    else
        NODE_OPTIONS="--max-old-space-size=512"
        log_info "检测到充足内存 ($TOTAL_MEM MB)，使用 512MB 内存限制"
    fi
    
    export NODE_OPTIONS="$NODE_OPTIONS"
    export NODE_ENV="production"
    
    log_success "环境变量设置完成"
}

# 安装依赖
install_dependencies() {
    log_info "安装后端依赖..."
    npm install
    
    log_info "安装前端依赖..."
    cd frontend
    npm install
    npm run build
    cd ..
    
    log_success "依赖安装完成"
}

# 运行轻量级构建
run_lightweight_build() {
    log_info "运行轻量级构建..."
    npm run lightweight-build
    log_success "轻量级构建完成"
}

# 创建必要目录
create_directories() {
    log_info "创建必要目录..."
    mkdir -p logs builds temp data
    log_success "目录创建完成"
}

# 配置PM2
setup_pm2() {
    log_info "配置PM2..."
    
    # 安装PM2
    if ! command -v pm2 &> /dev/null; then
        log_info "安装PM2..."
        npm install -g pm2
    fi
    
    # 创建PM2配置文件
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
      NODE_OPTIONS: '$NODE_OPTIONS',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
EOF
    
    log_success "PM2配置完成"
}

# 启动应用
start_application() {
    log_info "启动应用..."
    
    # 停止现有进程
    pm2 stop ez-theme-builder 2>/dev/null || true
    pm2 delete ez-theme-builder 2>/dev/null || true
    
    # 启动新进程
    pm2 start ecosystem.config.js
    
    # 设置开机自启
    pm2 startup
    pm2 save
    
    log_success "应用启动完成"
}

# 显示部署信息
show_deployment_info() {
    log_success "宝塔面板部署完成！"
    echo
    echo "=== 部署信息 ==="
    echo "项目目录: $(pwd)"
    echo "Node.js 版本: $(node --version)"
    echo "npm 版本: $(npm --version)"
    echo "内存限制: $NODE_OPTIONS"
    echo "环境: $NODE_ENV"
    echo
    echo "=== 访问地址 ==="
    echo "用户界面: http://你的域名"
    echo "管理后台: http://你的域名/admin"
    echo "API 文档: http://你的域名/api/health"
    echo
    echo "=== 管理命令 ==="
    echo "PM2 状态: pm2 status"
    echo "PM2 监控: pm2 monit"
    echo "PM2 日志: pm2 logs"
    echo "PM2 重启: pm2 restart ez-theme-builder"
    echo "PM2 停止: pm2 stop ez-theme-builder"
    echo
    echo "=== 宝塔面板配置 ==="
    echo "1. 在宝塔面板中为网站配置反向代理"
    echo "2. 目标URL: http://127.0.0.1:3000"
    echo "3. 配置SSL证书（可选）"
    echo
    echo "=== 日志文件 ==="
    echo "应用日志: logs/"
    echo "构建日志: temp/"
    echo
}

# 主函数
main() {
    echo "🚀 EZ-Theme Builder 宝塔面板部署脚本"
    echo "====================================="
    echo
    
    check_root
    check_baota
    check_nodejs
    setup_project
    setup_environment
    install_dependencies
    run_lightweight_build
    create_directories
    setup_pm2
    start_application
    show_deployment_info
}

# 错误处理
trap 'log_error "部署过程中发生错误，请检查日志"; exit 1' ERR

# 运行主函数
main "$@"
