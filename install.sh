#!/bin/bash

# EZ-Theme 自动打包系统安装脚本
# 适用于宝塔面板

echo "=========================================="
echo "EZ-Theme 自动打包系统安装脚本"
echo "=========================================="

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "请使用root用户运行此脚本"
    exit 1
fi

# 检查Node.js是否已安装
if ! command -v node &> /dev/null; then
    echo "正在安装Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    apt-get install -y nodejs
else
    echo "Node.js已安装: $(node --version)"
fi

# 检查npm是否已安装
if ! command -v npm &> /dev/null; then
    echo "正在安装npm..."
    apt-get install -y npm
else
    echo "npm已安装: $(npm --version)"
fi

# 创建应用目录
APP_DIR="/www/wwwroot/ez-theme-builder"
echo "创建应用目录: $APP_DIR"
mkdir -p $APP_DIR
cd $APP_DIR

# 复制项目文件
echo "正在复制项目文件..."
# 这里需要手动上传项目文件到服务器

# 安装后端依赖
echo "安装后端依赖..."
npm install

# 安装前端依赖
echo "安装前端依赖..."
cd frontend
npm install
cd ..

# 构建前端
echo "构建前端..."
npm run build

# 创建必要的目录
echo "创建必要的目录..."
mkdir -p builds
mkdir -p temp
mkdir -p logs

# 设置权限
echo "设置文件权限..."
chown -R www:www $APP_DIR
chmod -R 755 $APP_DIR

# 创建systemd服务文件
echo "创建systemd服务..."
cat > /etc/systemd/system/ez-theme-builder.service << EOF
[Unit]
Description=EZ-Theme Builder Service
After=network.target

[Service]
Type=simple
User=www
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=3000

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd
systemctl daemon-reload

# 启动服务
echo "启动服务..."
systemctl enable ez-theme-builder
systemctl start ez-theme-builder

# 检查服务状态
if systemctl is-active --quiet ez-theme-builder; then
    echo "✅ 服务启动成功"
else
    echo "❌ 服务启动失败"
    systemctl status ez-theme-builder
    exit 1
fi

# 创建Nginx配置文件
echo "创建Nginx配置..."
cat > /www/server/panel/vhost/nginx/ez-theme-builder.conf << EOF
server {
    listen 80;
    server_name your-domain.com;  # 请修改为您的域名
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /api {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

echo "=========================================="
echo "安装完成！"
echo "=========================================="
echo "服务地址: http://your-domain.com"
echo "管理后台: http://your-domain.com/admin"
echo "默认管理员账户: admin / admin123"
echo ""
echo "请完成以下配置："
echo "1. 修改Nginx配置文件中的域名"
echo "2. 配置SSL证书"
echo "3. 修改EZ-Theme路径配置"
echo "4. 配置支付接口"
echo "5. 重启Nginx服务"
echo ""
echo "常用命令："
echo "启动服务: systemctl start ez-theme-builder"
echo "停止服务: systemctl stop ez-theme-builder"
echo "重启服务: systemctl restart ez-theme-builder"
echo "查看状态: systemctl status ez-theme-builder"
echo "查看日志: journalctl -u ez-theme-builder -f"
