#!/bin/bash

# EZ-Theme Builder Git仓库修复脚本

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

# 修复Git仓库问题
fix_git_repository() {
    PROJECT_DIR="/www/wwwroot/ez-theme-builder"
    
    log_info "检查项目目录: $PROJECT_DIR"
    
    if [ ! -d "$PROJECT_DIR" ]; then
        log_info "项目目录不存在，创建目录..."
        mkdir -p "$PROJECT_DIR"
    fi
    
    cd "$PROJECT_DIR"
    
    # 检查是否为Git仓库
    if [ ! -d ".git" ]; then
        log_warning "当前目录不是Git仓库，重新克隆项目..."
        
        # 备份现有文件（如果有）
        if [ "$(ls -A)" ]; then
            log_info "备份现有文件..."
            BACKUP_DIR="/tmp/ez-theme-builder-backup-$(date +%Y%m%d_%H%M%S)"
            mkdir -p "$BACKUP_DIR"
            cp -r * "$BACKUP_DIR/" 2>/dev/null || true
            log_success "文件已备份到: $BACKUP_DIR"
        fi
        
        # 清空目录
        rm -rf * .* 2>/dev/null || true
        
        # 重新克隆项目
        log_info "重新克隆项目..."
        git clone https://github.com/wxfyes/ez-theme-builder.git .
        
        if [ $? -eq 0 ]; then
            log_success "项目克隆成功"
        else
            log_error "项目克隆失败"
            exit 1
        fi
    else
        log_info "Git仓库存在，尝试更新..."
        
        # 检查远程仓库
        if ! git remote -v | grep -q "origin"; then
            log_warning "没有远程仓库，添加origin..."
            git remote add origin https://github.com/wxfyes/ez-theme-builder.git
        fi
        
        # 拉取最新代码
        log_info "拉取最新代码..."
        git fetch origin
        git reset --hard origin/main
        
        log_success "代码更新成功"
    fi
}

# 设置环境变量
setup_environment() {
    log_info "设置环境变量..."
    
    # 检测系统内存
    TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    
    if [ "$TOTAL_MEM" -lt 1024 ]; then
        NODE_OPTIONS="--max-old-space-size=256"
        log_warning "检测到内存小于1GB，设置内存限制为256MB"
    elif [ "$TOTAL_MEM" -lt 2048 ]; then
        NODE_OPTIONS="--max-old-space-size=512"
        log_info "检测到内存1-2GB，设置内存限制为512MB"
    else
        NODE_OPTIONS="--max-old-space-size=1024"
        log_info "检测到内存大于2GB，设置内存限制为1024MB"
    fi
    
    export NODE_OPTIONS="$NODE_OPTIONS"
    export NODE_ENV="production"
    
    # 添加到.bashrc
    if ! grep -q "NODE_OPTIONS.*ez-theme" ~/.bashrc 2>/dev/null; then
        echo "export NODE_OPTIONS=\"$NODE_OPTIONS\"" >> ~/.bashrc
        echo "export NODE_ENV=\"production\"" >> ~/.bashrc
        log_success "环境变量已添加到.bashrc"
    fi
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

# 设置PM2
setup_pm2() {
    log_info "检查PM2..."
    
    if ! command -v pm2 &> /dev/null; then
        log_info "安装PM2..."
        npm install -g pm2
    fi
    
    # 创建PM2配置文件
    log_info "创建PM2配置..."
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
    
    log_success "PM2配置创建完成"
}

# 启动应用
start_application() {
    log_info "启动应用..."
    
    # 停止旧进程
    pm2 stop ez-theme-builder 2>/dev/null || true
    pm2 delete ez-theme-builder 2>/dev/null || true
    
    # 启动新进程
    pm2 start ecosystem.config.js
    pm2 startup
    pm2 save
    
    log_success "应用启动成功"
}

# 显示部署信息
show_deployment_info() {
    log_success "Git仓库修复完成！"
    echo
    echo "=== 部署信息 ==="
    echo "项目目录: /www/wwwroot/ez-theme-builder"
    echo "内存配置: $NODE_OPTIONS"
    echo "PM2状态: $(pm2 status | grep ez-theme-builder || echo '未运行')"
    echo
    echo "=== 访问地址 ==="
    echo "用户界面: http://你的域名"
    echo "管理后台: http://你的域名/admin"
    echo "API健康检查: http://你的域名/api/health"
    echo
    echo "=== 管理命令 ==="
    echo "查看状态: pm2 status"
    echo "查看日志: pm2 logs"
    echo "重启应用: pm2 restart ez-theme-builder"
    echo "停止应用: pm2 stop ez-theme-builder"
    echo
}

# 主函数
main() {
    echo "🔧 EZ-Theme Builder Git仓库修复脚本"
    echo "=================================="
    echo
    
    check_root
    fix_git_repository
    setup_environment
    install_dependencies
    run_lightweight_build
    create_directories
    setup_pm2
    start_application
    show_deployment_info
}

# 错误处理
trap 'log_error "修复过程中发生错误，请检查日志"; exit 1' ERR

# 运行主函数
main "$@"
