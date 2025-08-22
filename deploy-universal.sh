#!/bin/bash

# EZ-Theme Builder 通用部署脚本
# 适用于各种服务器平台

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查系统要求
check_requirements() {
    log_info "检查系统要求..."
    
    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js 未安装"
        log_info "正在安装 Node.js..."
        install_nodejs
    else
        NODE_VERSION=$(node --version)
        log_success "Node.js 已安装: $NODE_VERSION"
    fi
    
    # 检查 npm
    if ! command -v npm &> /dev/null; then
        log_error "npm 未安装"
        exit 1
    else
        NPM_VERSION=$(npm --version)
        log_success "npm 已安装: $NPM_VERSION"
    fi
    
    # 检查 git
    if ! command -v git &> /dev/null; then
        log_error "git 未安装"
        log_info "正在安装 git..."
        install_git
    else
        GIT_VERSION=$(git --version)
        log_success "git 已安装: $GIT_VERSION"
    fi
}

# 安装 Node.js
install_nodejs() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt-get &> /dev/null; then
            # Ubuntu/Debian
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y nodejs
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
            sudo yum install -y nodejs
        else
            log_error "不支持的 Linux 发行版"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install node
        else
            log_error "请先安装 Homebrew"
            exit 1
        fi
    else
        log_error "不支持的操作系统"
        exit 1
    fi
}

# 安装 git
install_git() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y git
        elif command -v yum &> /dev/null; then
            sudo yum install -y git
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install git
        fi
    fi
}

# 设置环境变量
setup_environment() {
    log_info "设置环境变量..."
    
    # 检测内存大小
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        TOTAL_MEM=$(sysctl hw.memsize | awk '{print $2}')
        TOTAL_MEM=$((TOTAL_MEM / 1024 / 1024))
    fi
    
    # 根据内存大小设置 Node.js 内存限制
    if [ "$TOTAL_MEM" -lt 512 ]; then
        NODE_OPTIONS="--max-old-space-size=128"
        log_warning "检测到内存较小 ($TOTAL_MEM MB)，使用 128MB 内存限制"
    elif [ "$TOTAL_MEM" -lt 1024 ]; then
        NODE_OPTIONS="--max-old-space-size=256"
        log_info "检测到中等内存 ($TOTAL_MEM MB)，使用 256MB 内存限制"
    else
        NODE_OPTIONS="--max-old-space-size=512"
        log_info "检测到充足内存 ($TOTAL_MEM MB)，使用 512MB 内存限制"
    fi
    
    export NODE_OPTIONS="$NODE_OPTIONS"
    export NODE_ENV="production"
    
    log_success "环境变量设置完成"
}

# 克隆或更新项目
setup_project() {
    PROJECT_DIR="ez-theme-builder"
    
    if [ -d "$PROJECT_DIR" ]; then
        log_info "项目已存在，正在更新..."
        cd "$PROJECT_DIR"
        git pull origin main
    else
        log_info "克隆项目..."
        git clone https://github.com/your-username/ez-theme-builder.git
        cd "$PROJECT_DIR"
    fi
    
    log_success "项目设置完成"
}

# 安装依赖
install_dependencies() {
    log_info "安装后端依赖..."
    npm install
    
    log_info "安装前端依赖..."
    cd frontend
    npm install
    cd ..
    
    log_success "依赖安装完成"
}

# 构建前端
build_frontend() {
    log_info "构建前端..."
    cd frontend
    npm run build
    cd ..
    log_success "前端构建完成"
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
    mkdir -p builds temp data logs
    log_success "目录创建完成"
}

# 设置 PM2 (可选)
setup_pm2() {
    read -p "是否使用 PM2 管理进程？(y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "安装 PM2..."
        npm install -g pm2
        
        log_info "配置 PM2..."
        cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'ez-theme-builder',
    script: 'server.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '256M',
    env: {
      NODE_ENV: 'production',
      NODE_OPTIONS: '$NODE_OPTIONS'
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
EOF
        
        log_success "PM2 配置完成"
        USE_PM2=true
    else
        USE_PM2=false
    fi
}

# 启动应用
start_application() {
    log_info "启动应用..."
    
    if [ "$USE_PM2" = true ]; then
        pm2 start ecosystem.config.js
        pm2 save
        pm2 startup
        log_success "应用已通过 PM2 启动"
        log_info "使用 'pm2 monit' 监控应用"
        log_info "使用 'pm2 logs' 查看日志"
    else
        log_info "直接启动应用..."
        log_info "按 Ctrl+C 停止应用"
        npm start
    fi
}

# 显示部署信息
show_deployment_info() {
    log_success "部署完成！"
    echo
    echo "=== 部署信息 ==="
    echo "项目目录: $(pwd)"
    echo "Node.js 版本: $(node --version)"
    echo "npm 版本: $(npm --version)"
    echo "内存限制: $NODE_OPTIONS"
    echo "环境: $NODE_ENV"
    echo
    echo "=== 访问地址 ==="
    echo "用户界面: http://localhost:3000"
    echo "管理后台: http://localhost:3000/admin"
    echo "API 文档: http://localhost:3000/api/health"
    echo
    echo "=== 管理命令 ==="
    if [ "$USE_PM2" = true ]; then
        echo "PM2 状态: pm2 status"
        echo "PM2 监控: pm2 monit"
        echo "PM2 日志: pm2 logs"
        echo "PM2 重启: pm2 restart ez-theme-builder"
        echo "PM2 停止: pm2 stop ez-theme-builder"
    else
        echo "启动: npm start"
        echo "开发模式: npm run dev"
    fi
    echo
    echo "=== 日志文件 ==="
    echo "应用日志: logs/"
    echo "构建日志: temp/"
    echo
}

# 主函数
main() {
    echo "🚀 EZ-Theme Builder 通用部署脚本"
    echo "=================================="
    echo
    
    # 检查是否为 root 用户
    if [ "$EUID" -eq 0 ]; then
        log_warning "检测到 root 用户，建议使用普通用户运行"
        read -p "是否继续？(y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # 执行部署步骤
    check_requirements
    setup_environment
    setup_project
    install_dependencies
    build_frontend
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
