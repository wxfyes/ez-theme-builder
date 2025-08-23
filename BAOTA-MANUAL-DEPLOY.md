# 宝塔面板 Node.js 管理器部署指南

## 🎯 前置条件

1. **已安装宝塔面板**
2. **已安装 Node.js 管理器**（在宝塔面板软件商店中安装）

## 🚀 一键部署

```bash
# 下载部署脚本
wget -O baota-node-deploy.sh https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/baota-node-deploy.sh
chmod +x baota-node-deploy.sh

# 运行部署
./baota-node-deploy.sh
```

## 📋 手动部署步骤

### 1. 安装 Node.js 管理器

在宝塔面板中：
- 进入 **软件商店**
- 搜索 **Node.js 管理器**
- 点击 **安装**

### 2. 创建项目目录

```bash
mkdir -p /www/wwwroot/ez-theme-builder
cd /www/wwwroot/ez-theme-builder
```

### 3. 下载项目

```bash
wget -O ez-theme-builder.zip https://github.com/wxfyes/ez-theme-builder/archive/refs/heads/main.zip
unzip ez-theme-builder.zip
mv ez-theme-builder-main/* .
rm -rf ez-theme-builder-main ez-theme-builder.zip
```

### 4. 设置 Node.js 环境

```bash
export PATH="/www/server/nodejs/22.18.0/bin:$PATH"
```

### 5. 安装依赖

```bash
# 安装后端依赖
npm install --force --no-optional

# 安装前端依赖
cd frontend
npm install --force --no-optional

# 安装 vite
npm install -g vite @vitejs/plugin-vue

# 构建前端
npm run build
cd ..
```

### 6. 创建必要目录

```bash
mkdir -p logs builds temp data
chmod -R 755 .
chown -R www:www .
```

### 7. 安装 PM2

```bash
npm install -g pm2
```

### 8. 创建 PM2 配置

```bash
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'ez-theme-builder',
    script: 'server.js',
    cwd: '/www/wwwroot/ez-theme-builder',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '512M',
    env: {
      NODE_ENV: 'production',
      PORT: 3000,
      NODE_OPTIONS: '--max-old-space-size=512'
    },
    error_file: '/www/wwwroot/ez-theme-builder/logs/err.log',
    out_file: '/www/wwwroot/ez-theme-builder/logs/out.log',
    log_file: '/www/wwwroot/ez-theme-builder/logs/combined.log',
    time: true
  }]
}
EOF
```

### 9. 启动应用

```bash
pm2 start ecosystem.config.js
pm2 startup
pm2 save
```

## 🌐 宝塔面板网站配置

### 方法一：反向代理（推荐）

1. **创建网站**
   - 域名：你的域名或IP
   - 根目录：`/www/wwwroot/ez-theme-builder`

2. **配置反向代理**
   - 进入网站设置
   - 点击 **反向代理**
   - 添加代理：
     - 代理名称：`ez-theme-builder`
     - 目标URL：`http://127.0.0.1:3000`
     - 发送域名：`$host`

### 方法二：直接访问

直接访问：`http://你的服务器IP:3000`

## 📊 管理命令

```bash
# 查看状态
pm2 status

# 启动应用
pm2 start ez-theme-builder

# 停止应用
pm2 stop ez-theme-builder

# 重启应用
pm2 restart ez-theme-builder

# 查看日志
pm2 logs ez-theme-builder

# 查看详细信息
pm2 show ez-theme-builder
```

## 🔧 故障排除

### 1. 端口被占用

```bash
# 查看端口占用
netstat -tlnp | grep :3000

# 杀死占用进程
pkill -f "node.*3000"
```

### 2. 权限问题

```bash
# 重新设置权限
chown -R www:www /www/wwwroot/ez-theme-builder
chmod -R 755 /www/wwwroot/ez-theme-builder
```

### 3. 内存不足

```bash
# 增加内存限制
export NODE_OPTIONS="--max-old-space-size=1024"
pm2 restart ez-theme-builder
```

### 4. 查看详细日志

```bash
# PM2 日志
pm2 logs ez-theme-builder --lines 50

# 应用日志
tail -f /www/wwwroot/ez-theme-builder/logs/combined.log
```

## 🎉 完成

部署完成后，你可以通过以下方式访问：

- **反向代理**：`http://你的域名`
- **直接访问**：`http://你的服务器IP:3000`

## 💡 提示

1. **确保防火墙开放 3000 端口**
2. **如果使用域名，确保 DNS 解析正确**
3. **定期备份项目文件**
4. **监控应用状态和日志**

## 🎯 前置条件

1. **已安装宝塔面板**
2. **已安装 Node.js 管理器**（在宝塔面板软件商店中安装）

## 🚀 一键部署

```bash
# 下载部署脚本
wget -O baota-node-deploy.sh https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/baota-node-deploy.sh
chmod +x baota-node-deploy.sh

# 运行部署
./baota-node-deploy.sh
```

## 📋 手动部署步骤

### 1. 安装 Node.js 管理器

在宝塔面板中：
- 进入 **软件商店**
- 搜索 **Node.js 管理器**
- 点击 **安装**

### 2. 创建项目目录

```bash
mkdir -p /www/wwwroot/ez-theme-builder
cd /www/wwwroot/ez-theme-builder
```

### 3. 下载项目

```bash
wget -O ez-theme-builder.zip https://github.com/wxfyes/ez-theme-builder/archive/refs/heads/main.zip
unzip ez-theme-builder.zip
mv ez-theme-builder-main/* .
rm -rf ez-theme-builder-main ez-theme-builder.zip
```

### 4. 设置 Node.js 环境

```bash
export PATH="/www/server/nodejs/22.18.0/bin:$PATH"
```

### 5. 安装依赖

```bash
# 安装后端依赖
npm install --force --no-optional

# 安装前端依赖
cd frontend
npm install --force --no-optional

# 安装 vite
npm install -g vite @vitejs/plugin-vue

# 构建前端
npm run build
cd ..
```

### 6. 创建必要目录

```bash
mkdir -p logs builds temp data
chmod -R 755 .
chown -R www:www .
```

### 7. 安装 PM2

```bash
npm install -g pm2
```

### 8. 创建 PM2 配置

```bash
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'ez-theme-builder',
    script: 'server.js',
    cwd: '/www/wwwroot/ez-theme-builder',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '512M',
    env: {
      NODE_ENV: 'production',
      PORT: 3000,
      NODE_OPTIONS: '--max-old-space-size=512'
    },
    error_file: '/www/wwwroot/ez-theme-builder/logs/err.log',
    out_file: '/www/wwwroot/ez-theme-builder/logs/out.log',
    log_file: '/www/wwwroot/ez-theme-builder/logs/combined.log',
    time: true
  }]
}
EOF
```

### 9. 启动应用

```bash
pm2 start ecosystem.config.js
pm2 startup
pm2 save
```

## 🌐 宝塔面板网站配置

### 方法一：反向代理（推荐）

1. **创建网站**
   - 域名：你的域名或IP
   - 根目录：`/www/wwwroot/ez-theme-builder`

2. **配置反向代理**
   - 进入网站设置
   - 点击 **反向代理**
   - 添加代理：
     - 代理名称：`ez-theme-builder`
     - 目标URL：`http://127.0.0.1:3000`
     - 发送域名：`$host`

### 方法二：直接访问

直接访问：`http://你的服务器IP:3000`

## 📊 管理命令

```bash
# 查看状态
pm2 status

# 启动应用
pm2 start ez-theme-builder

# 停止应用
pm2 stop ez-theme-builder

# 重启应用
pm2 restart ez-theme-builder

# 查看日志
pm2 logs ez-theme-builder

# 查看详细信息
pm2 show ez-theme-builder
```

## 🔧 故障排除

### 1. 端口被占用

```bash
# 查看端口占用
netstat -tlnp | grep :3000

# 杀死占用进程
pkill -f "node.*3000"
```

### 2. 权限问题

```bash
# 重新设置权限
chown -R www:www /www/wwwroot/ez-theme-builder
chmod -R 755 /www/wwwroot/ez-theme-builder
```

### 3. 内存不足

```bash
# 增加内存限制
export NODE_OPTIONS="--max-old-space-size=1024"
pm2 restart ez-theme-builder
```

### 4. 查看详细日志

```bash
# PM2 日志
pm2 logs ez-theme-builder --lines 50

# 应用日志
tail -f /www/wwwroot/ez-theme-builder/logs/combined.log
```

## 🎉 完成

部署完成后，你可以通过以下方式访问：

- **反向代理**：`http://你的域名`
- **直接访问**：`http://你的服务器IP:3000`

## 💡 提示

1. **确保防火墙开放 3000 端口**
2. **如果使用域名，确保 DNS 解析正确**
3. **定期备份项目文件**
4. **监控应用状态和日志**
