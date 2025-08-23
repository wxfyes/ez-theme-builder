#!/bin/bash

# EZ-Theme Builder 宝塔面板一键删除脚本

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

# 确认删除
confirm_removal() {
    echo
    log_warning "⚠️  警告：此操作将完全删除 EZ-Theme Builder 项目"
    echo
    echo "将删除以下内容："
    echo "- 项目目录: /www/wwwroot/ez-theme-builder"
    echo "- PM2 进程: ez-theme-builder"
    echo "- 所有构建文件和日志"
    echo "- 数据库文件（如果存在）"
    echo
    read -p "确定要删除吗？(输入 'yes' 确认): " confirm
    
    if [ "$confirm" != "yes" ]; then
        log_info "操作已取消"
        exit 0
    fi
    
    log_info "开始删除..."
}

# 停止PM2进程
stop_pm2() {
    log_info "停止PM2进程..."
    
    if command -v pm2 &> /dev/null; then
        # 停止进程
        pm2 stop ez-theme-builder 2>/dev/null || true
        pm2 delete ez-theme-builder 2>/dev/null || true
        
        # 保存PM2配置
        pm2 save 2>/dev/null || true
        
        log_success "PM2进程已停止并删除"
    else
        log_warning "PM2未安装，跳过进程停止"
    fi
}

# 删除项目目录
remove_project_directory() {
    PROJECT_DIR="/www/wwwroot/ez-theme-builder"
    
    log_info "删除项目目录: $PROJECT_DIR"
    
    if [ -d "$PROJECT_DIR" ]; then
        # 显示目录大小
        DIR_SIZE=$(du -sh "$PROJECT_DIR" 2>/dev/null | cut -f1)
        log_info "项目目录大小: $DIR_SIZE"
        
        # 删除目录
        rm -rf "$PROJECT_DIR"
        log_success "项目目录已删除"
    else
        log_warning "项目目录不存在，跳过删除"
    fi
}

# 删除临时目录
remove_temp_directories() {
    log_info "删除临时目录..."
    
    TEMP_DIRS=(
        "/tmp/temp-base-build"
        "/tmp/temp-lightweight"
        "/tmp/temp-vercel"
        "/tmp/temp-safe-build"
    )
    
    for dir in "${TEMP_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            log_info "删除临时目录: $dir"
        fi
    done
    
    log_success "临时目录清理完成"
}

# 清理npm缓存
clean_npm_cache() {
    log_info "清理npm缓存..."
    
    if command -v npm &> /dev/null; then
        npm cache clean --force 2>/dev/null || true
        log_success "npm缓存已清理"
    else
        log_warning "npm未安装，跳过缓存清理"
    fi
}

# 删除Node.js模块（可选）
remove_node_modules() {
    echo
    read -p "是否删除全局Node.js模块？(y/n): " remove_global
    
    if [ "$remove_global" = "y" ] || [ "$remove_global" = "Y" ]; then
        log_info "删除全局Node.js模块..."
        
        # 删除PM2
        npm uninstall -g pm2 2>/dev/null || true
        
        # 删除其他可能的全局模块
        npm uninstall -g nodemon 2>/dev/null || true
        npm uninstall -g forever 2>/dev/null || true
        
        log_success "全局Node.js模块已删除"
    else
        log_info "保留全局Node.js模块"
    fi
}

# 清理系统日志
clean_system_logs() {
    log_info "清理系统日志..."
    
    # 清理可能的日志文件
    LOG_FILES=(
        "/var/log/ez-theme-builder.log"
        "/var/log/ez-theme-builder-error.log"
        "/var/log/ez-theme-builder-access.log"
    )
    
    for log_file in "${LOG_FILES[@]}"; do
        if [ -f "$log_file" ]; then
            rm -f "$log_file"
            log_info "删除日志文件: $log_file"
        fi
    done
    
    log_success "系统日志清理完成"
}

# 清理数据库文件
clean_database() {
    log_info "检查数据库文件..."
    
    DB_FILES=(
        "/www/wwwroot/ez-theme-builder/database.sqlite"
        "/www/wwwroot/ez-theme-builder/data/database.sqlite"
        "/www/wwwroot/ez-theme-builder/db.sqlite"
    )
    
    for db_file in "${DB_FILES[@]}"; do
        if [ -f "$db_file" ]; then
            log_warning "发现数据库文件: $db_file"
            read -p "是否删除数据库文件？(y/n): " remove_db
            
            if [ "$remove_db" = "y" ] || [ "$remove_db" = "Y" ]; then
                rm -f "$db_file"
                log_success "数据库文件已删除: $db_file"
            else
                log_info "保留数据库文件: $db_file"
            fi
        fi
    done
}

# 清理环境变量
clean_environment() {
    log_info "清理环境变量..."
    
    # 从.bashrc中移除相关环境变量
    if [ -f ~/.bashrc ]; then
        # 备份.bashrc
        cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)
        
        # 移除EZ-Theme Builder相关的环境变量
        sed -i '/EZ_THEME_BUILDER/d' ~/.bashrc
        sed -i '/JWT_SECRET.*ez-theme/d' ~/.bashrc
        
        log_success "环境变量已清理"
    fi
}

# 清理宝塔面板配置（可选）
clean_baota_config() {
    echo
    read -p "是否清理宝塔面板中的网站配置？(y/n): " clean_baota
    
    if [ "$clean_baota" = "y" ] || [ "$clean_baota" = "Y" ]; then
        log_info "清理宝塔面板配置..."
        
        # 这里可以添加清理宝塔面板配置的命令
        # 由于宝塔面板的配置比较复杂，建议手动清理
        
        log_warning "请手动在宝塔面板中删除网站配置："
        echo "1. 登录宝塔面板"
        echo "2. 进入 '网站' 管理"
        echo "3. 删除 'ez-theme-builder' 网站"
        echo "4. 删除相关的SSL证书（如果有）"
        echo "5. 清理反向代理配置"
    else
        log_info "保留宝塔面板配置"
    fi
}

# 显示清理结果
show_cleanup_result() {
    log_success "EZ-Theme Builder 删除完成！"
    echo
    echo "=== 清理内容 ==="
    echo "✅ PM2进程已停止并删除"
    echo "✅ 项目目录已删除"
    echo "✅ 临时目录已清理"
    echo "✅ npm缓存已清理"
    echo "✅ 系统日志已清理"
    echo "✅ 环境变量已清理"
    echo
    echo "=== 注意事项 ==="
    echo "⚠️  如果配置了宝塔面板网站，请手动删除"
    echo "⚠️  如果使用了自定义域名，请更新DNS记录"
    echo "⚠️  如果配置了SSL证书，请手动清理"
    echo
    echo "=== 恢复建议 ==="
    echo "如需重新部署，请运行："
    echo "wget https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/deploy-baota.sh"
    echo "chmod +x deploy-baota.sh"
    echo "./deploy-baota.sh"
    echo
}

# 主函数
main() {
    echo "🗑️  EZ-Theme Builder 宝塔面板一键删除脚本"
    echo "========================================="
    echo
    
    check_root
    confirm_removal
    stop_pm2
    remove_project_directory
    remove_temp_directories
    clean_npm_cache
    remove_node_modules
    clean_system_logs
    clean_database
    clean_environment
    clean_baota_config
    show_cleanup_result
}

# 错误处理
trap 'log_error "删除过程中发生错误，请检查日志"; exit 1' ERR

# 运行主函数
main "$@"
