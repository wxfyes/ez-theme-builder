#!/bin/bash

# EZ-Theme Builder 构建工具修复脚本

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

# 检查Node.js和npm
check_nodejs() {
    log_info "检查Node.js环境..."
    
    if ! command -v node &> /dev/null; then
        log_error "Node.js未安装，请先安装Node.js"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        log_error "npm未安装，请先安装npm"
        exit 1
    fi
    
    NODE_VERSION=$(node -v)
    NPM_VERSION=$(npm -v)
    
    log_success "Node.js版本: $NODE_VERSION"
    log_success "npm版本: $NPM_VERSION"
}

# 清理并重新安装依赖
clean_and_install() {
    PROJECT_DIR="/www/wwwroot/ez-theme-builder"
    
    if [ ! -d "$PROJECT_DIR" ]; then
        log_error "项目目录不存在: $PROJECT_DIR"
        exit 1
    fi
    
    cd "$PROJECT_DIR"
    
    log_info "清理node_modules..."
    rm -rf node_modules package-lock.json
    
    log_info "清理前端node_modules..."
    rm -rf frontend/node_modules frontend/package-lock.json
    
    log_info "清理npm缓存..."
    npm cache clean --force
    
    log_info "重新安装后端依赖..."
    npm install
    
    log_info "重新安装前端依赖..."
    cd frontend
    npm install
    cd ..
    
    log_success "依赖重新安装完成"
}

# 安装全局构建工具
install_global_tools() {
    log_info "安装全局构建工具..."
    
    # 安装Vue CLI
    log_info "安装Vue CLI..."
    npm install -g @vue/cli
    
    # 安装Vite
    log_info "安装Vite..."
    npm install -g vite
    
    # 安装其他可能需要的工具
    log_info "安装其他构建工具..."
    npm install -g @vue/cli-service
    npm install -g @vue/cli-plugin-babel
    npm install -g @vue/cli-plugin-eslint
    
    log_success "全局构建工具安装完成"
}

# 检查构建工具
check_build_tools() {
    log_info "检查构建工具..."
    
    # 检查vue-cli-service
    if ! command -v vue-cli-service &> /dev/null; then
        log_warning "vue-cli-service未找到，尝试本地安装..."
        cd frontend
        npm install @vue/cli-service --save-dev
        cd ..
    else
        log_success "vue-cli-service已安装"
    fi
    
    # 检查vite
    if ! command -v vite &> /dev/null; then
        log_warning "vite未找到，尝试本地安装..."
        cd frontend
        npm install vite --save-dev
        cd ..
    else
        log_success "vite已安装"
    fi
    
    # 检查npx
    if ! command -v npx &> /dev/null; then
        log_warning "npx未找到，安装npx..."
        npm install -g npx
    fi
}

# 修复package.json脚本
fix_package_scripts() {
    log_info "检查并修复package.json脚本..."
    
    cd frontend
    
    # 检查package.json是否存在
    if [ ! -f "package.json" ]; then
        log_error "frontend/package.json不存在"
        exit 1
    fi
    
    # 备份package.json
    cp package.json package.json.backup
    
    # 修复构建脚本
    log_info "修复构建脚本..."
    
    # 使用npx确保使用本地安装的工具
    sed -i 's/"build": "vite build"/"build": "npx vite build"/g' package.json
    sed -i 's/"build": "vue-cli-service build"/"build": "npx vue-cli-service build"/g' package.json
    
    log_success "package.json脚本修复完成"
    
    cd ..
}

# 测试构建
test_build() {
    log_info "测试前端构建..."
    
    cd frontend
    
    # 尝试使用npx运行构建
    if npx vite --version &> /dev/null; then
        log_info "使用Vite构建..."
        npx vite build
    elif npx vue-cli-service --version &> /dev/null; then
        log_info "使用Vue CLI构建..."
        npx vue-cli-service build
    else
        log_error "无法找到构建工具"
        exit 1
    fi
    
    cd ..
    
    log_success "前端构建测试成功"
}

# 运行完整构建
run_full_build() {
    log_info "运行完整构建流程..."
    
    cd "/www/wwwroot/ez-theme-builder"
    
    # 运行轻量级构建
    log_info "运行轻量级构建..."
    npm run lightweight-build
    
    log_success "完整构建流程完成"
}

# 创建目录并启动
setup_and_start() {
    log_info "创建必要目录..."
    mkdir -p logs builds temp data
    
    log_info "设置PM2..."
    
    if ! command -v pm2 &> /dev/null; then
        log_info "安装PM2..."
        npm install -g pm2
    fi
    
    # 创建PM2配置
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
      NODE_OPTIONS: '--max-old-space-size=512',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
EOF
    
    log_info "启动应用..."
    pm2 stop ez-theme-builder 2>/dev/null || true
    pm2 delete ez-theme-builder 2>/dev/null || true
    pm2 start ecosystem.config.js
    pm2 startup
    pm2 save
    
    log_success "应用启动成功"
}

# 显示修复结果
show_fix_result() {
    log_success "构建工具修复完成！"
    echo
    echo "=== 修复内容 ==="
    echo "✅ 清理并重新安装依赖"
    echo "✅ 安装全局构建工具"
    echo "✅ 修复package.json脚本"
    echo "✅ 测试构建流程"
    echo "✅ 启动应用"
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
    echo
}

# 主函数
main() {
    echo "🔧 EZ-Theme Builder 构建工具修复脚本"
    echo "=================================="
    echo
    
    check_root
    check_nodejs
    clean_and_install
    install_global_tools
    check_build_tools
    fix_package_scripts
    test_build
    run_full_build
    setup_and_start
    show_fix_result
}

# 错误处理
trap 'log_error "修复过程中发生错误，请检查日志"; exit 1' ERR

# 运行主函数
main "$@"
