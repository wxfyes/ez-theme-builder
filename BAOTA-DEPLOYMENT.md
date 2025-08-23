# 宝塔面板部署指南

## 🛠️ **宝塔面板安装**

### 1. 安装宝塔面板

#### CentOS系统：
```bash
yum install -y wget && wget -O install.sh http://download.bt.cn/install/install_6.0.sh && sh install.sh
```

#### Ubuntu/Debian系统：
```bash
wget -O install.sh http://download.bt.cn/install/install-ubuntu_6.0.sh && sudo bash install.sh
```

### 2. 安装完成后
- 记录显示的宝塔面板地址、用户名和密码
- 在浏览器中访问宝塔面板

## 📦 **安装必要软件**

### 1. 安装Node.js管理器
1. 登录宝塔面板
2. 点击左侧菜单 **"软件商店"**
3. 搜索 **"Node.js版本管理器"**
4. 点击 **"安装"**
5. 安装完成后，在Node.js管理器中安装 **Node.js 18.x**

### 2. 安装Git（如果没有）
```bash
# CentOS
yum install -y git

# Ubuntu/Debian
apt-get install -y git
```

## 🌐 **创建网站**

### 1. 添加站点
1. 点击左侧菜单 **"网站"**
2. 点击 **"添加站点"**
3. 填写信息：
   - **域名**: 你的域名或服务器IP
   - **根目录**: `/www/wwwroot/ez-theme-builder`
   - **PHP版本**: 选择 **"纯静态"**
   - **数据库**: 不创建
   - **FTP**: 不创建

### 2. 配置网站
1. 点击网站的 **"设置"**
2. 在 **"反向代理"** 中添加：
   - **代理名称**: `ez-theme-builder`
   - **目标URL**: `http://127.0.0.1:3000`

## 🚀 **部署项目**

### 方法一：使用自动部署脚本（推荐）

```bash
# 下载部署脚本
wget https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/deploy-baota.sh

# 给脚本执行权限
chmod +x deploy-baota.sh

# 运行部署脚本
./deploy-baota.sh
```

### 方法二：手动部署

#### 1. 克隆项目
```bash
cd /www/wwwroot/ez-theme-builder
git clone https://github.com/wxfyes/ez-theme-builder.git .
```

#### 2. 设置环境变量
```bash
export NODE_OPTIONS="--max-old-space-size=512"
export NODE_ENV="production"
```

#### 3. 安装依赖
```bash
# 安装后端依赖
npm install

# 安装前端依赖
cd frontend
npm install
npm run build
cd ..
```

#### 4. 运行轻量级构建
```bash
npm run lightweight-build
```

#### 5. 安装PM2
```bash
npm install -g pm2
```

#### 6. 创建PM2配置
```bash
cat > ecosystem.config.js << 'EOF'
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
```

#### 7. 创建目录并启动
```bash
mkdir -p logs builds temp data
pm2 start ecosystem.config.js
pm2 startup
pm2 save
```

## 🔧 **配置SSL证书（可选）**

### 1. 申请Let's Encrypt证书
1. 在网站设置中点击 **"SSL"**
2. 选择 **"Let's Encrypt"**
3. 点击 **"申请"**

### 2. 配置强制HTTPS
1. 在SSL设置中开启 **"强制HTTPS"**
2. 开启 **"HTTP/2"**

## 🛡️ **安全配置**

### 1. 防火墙设置
1. 在宝塔面板中点击 **"安全"**
2. 确保端口 **80** 和 **443** 开放
3. 端口 **3000** 不需要开放（内部使用）

### 2. 设置JWT密钥
```bash
# 在项目目录中设置环境变量
echo 'export JWT_SECRET="your-secret-key-here"' >> ~/.bashrc
source ~/.bashrc
```

## 📊 **监控和管理**

### 1. PM2管理命令
```bash
# 查看状态
pm2 status

# 查看日志
pm2 logs

# 重启应用
pm2 restart ez-theme-builder

# 停止应用
pm2 stop ez-theme-builder

# 监控
pm2 monit
```

### 2. 宝塔面板监控
1. 在宝塔面板中查看 **"系统监控"**
2. 监控CPU、内存、磁盘使用情况
3. 查看网站访问日志

## 🔍 **故障排除**

### 1. 常见问题

#### 端口被占用
```bash
# 查看端口占用
netstat -tulpn | grep :3000

# 杀死进程
kill -9 <PID>
```

#### 内存不足
```bash
# 减少内存限制
export NODE_OPTIONS="--max-old-space-size=256"
pm2 restart ez-theme-builder
```

#### 权限问题
```bash
# 修复权限
chown -R www:www /www/wwwroot/ez-theme-builder
chmod -R 755 /www/wwwroot/ez-theme-builder
```

### 2. 日志查看
```bash
# 查看PM2日志
pm2 logs ez-theme-builder

# 查看应用日志
tail -f /www/wwwroot/ez-theme-builder/logs/combined.log

# 查看错误日志
tail -f /www/wwwroot/ez-theme-builder/logs/err.log
```

## 📈 **性能优化**

### 1. 内存优化
- 根据服务器内存调整 `NODE_OPTIONS`
- 监控内存使用情况
- 定期重启应用释放内存

### 2. 缓存优化
- 在宝塔面板中开启 **"静态文件缓存"**
- 配置CDN加速
- 启用Gzip压缩

### 3. 数据库优化
- 定期清理日志文件
- 监控数据库大小
- 配置自动备份

## 🔄 **更新部署**

### 1. 自动更新
```bash
cd /www/wwwroot/ez-theme-builder
git pull origin main
npm install
cd frontend && npm install && npm run build && cd ..
npm run lightweight-build
pm2 restart ez-theme-builder
```

### 2. 使用部署脚本更新
```bash
./deploy-baota.sh
```

## 📋 **部署检查清单**

- [ ] 宝塔面板已安装
- [ ] Node.js已安装
- [ ] 网站已创建
- [ ] 反向代理已配置
- [ ] 项目已部署
- [ ] PM2已启动
- [ ] SSL证书已配置（可选）
- [ ] 防火墙已设置
- [ ] 域名可以访问
- [ ] 管理后台可以登录

## 🎯 **访问地址**

部署完成后，你可以通过以下地址访问：

- **用户界面**: `http://你的域名`
- **管理后台**: `http://你的域名/admin`
- **API文档**: `http://你的域名/api/health`

## 📞 **技术支持**

如果遇到问题：
1. 查看PM2日志：`pm2 logs`
2. 查看应用日志：`tail -f logs/combined.log`
3. 检查宝塔面板错误日志
4. 确认端口和防火墙设置

## 更新日志

### v1.5.0
- 添加宝塔面板部署指南
- 创建自动部署脚本
- 优化内存配置
- 添加故障排除指南
