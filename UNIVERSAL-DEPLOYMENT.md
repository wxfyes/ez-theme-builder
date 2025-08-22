# 通用部署指南 - 轻量级构建

## 支持的服务器平台

轻量级构建脚本可以在以下所有平台使用：

### 🚀 **云平台**
- **Render** (免费/付费)
- **Railway** (免费/付费)
- **Fly.io** (免费/付费)
- **Heroku** (免费/付费)
- **Vercel** (免费/付费)
- **Netlify** (免费/付费)

### 🖥️ **VPS/服务器**
- **阿里云 ECS**
- **腾讯云 CVM**
- **AWS EC2**
- **Google Cloud**
- **DigitalOcean**
- **Vultr**
- **Linode**

### 🐳 **容器平台**
- **Docker**
- **Kubernetes**
- **Docker Compose**

## 部署方式

### 1. 自动部署 (推荐)

#### Render
```yaml
# render.yaml
services:
  - type: web
    name: ez-theme-builder
    env: node
    plan: free
    buildCommand: |
      export NODE_OPTIONS="--max-old-space-size=256"
      npm install
      cd frontend && npm install && npm run build
      cd .. && npm run lightweight-build
      echo "轻量级构建完成"
    startCommand: |
      export NODE_OPTIONS="--max-old-space-size=256"
      npm start
```

#### Railway
```json
// railway.json
{
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "export NODE_OPTIONS='--max-old-space-size=256' && npm start",
    "healthcheckPath": "/api/health",
    "healthcheckTimeout": 300,
    "restartPolicyType": "ON_FAILURE"
  }
}
```

#### Fly.io
```toml
# fly.toml
[env]
  NODE_OPTIONS = "--max-old-space-size=256"
  NODE_ENV = "production"

[build]
  dockerfile = "Dockerfile"

[processes]
  app = "npm start"
```

### 2. 手动部署

#### 步骤 1: 克隆项目
```bash
git clone https://github.com/your-username/ez-theme-builder.git
cd ez-theme-builder
```

#### 步骤 2: 设置环境变量
```bash
export NODE_OPTIONS="--max-old-space-size=256"
export NODE_ENV="production"
export JWT_SECRET="your-secret-key"
```

#### 步骤 3: 安装依赖
```bash
npm install
cd frontend && npm install && npm run build
cd ..
```

#### 步骤 4: 运行轻量级构建
```bash
npm run lightweight-build
```

#### 步骤 5: 启动服务
```bash
npm start
```

### 3. Docker 部署

#### Dockerfile
```dockerfile
FROM node:18-alpine

WORKDIR /app

# 设置环境变量
ENV NODE_OPTIONS="--max-old-space-size=256"
ENV NODE_ENV="production"

# 复制项目文件
COPY package*.json ./
COPY frontend/package*.json ./frontend/

# 安装依赖
RUN npm install
RUN cd frontend && npm install

# 复制源代码
COPY . .

# 构建前端
RUN cd frontend && npm run build

# 运行轻量级构建
RUN npm run lightweight-build

# 创建必要目录
RUN mkdir -p builds temp data

EXPOSE 3000

CMD ["npm", "start"]
```

#### docker-compose.yml
```yaml
version: '3.8'
services:
  ez-theme-builder:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_OPTIONS=--max-old-space-size=256
      - NODE_ENV=production
      - JWT_SECRET=your-secret-key
    volumes:
      - ./data:/app/data
      - ./builds:/app/builds
      - ./temp:/app/temp
    restart: unless-stopped
```

## 内存配置建议

### 不同平台的内存限制

| 平台 | 免费计划内存 | 推荐设置 | 付费计划内存 |
|------|-------------|----------|-------------|
| Render | 512MB | 256MB | 1GB+ |
| Railway | 512MB | 256MB | 1GB+ |
| Fly.io | 256MB | 128MB | 1GB+ |
| Heroku | 512MB | 256MB | 1GB+ |
| Vercel | 1024MB | 512MB | 2GB+ |

### 内存优化配置

#### 低内存环境 (256MB)
```bash
export NODE_OPTIONS="--max-old-space-size=128"
```

#### 中等内存环境 (512MB)
```bash
export NODE_OPTIONS="--max-old-space-size=256"
```

#### 高内存环境 (1GB+)
```bash
export NODE_OPTIONS="--max-old-space-size=512"
```

## 平台特定配置

### 1. 阿里云 ECS

#### 系统要求
- Ubuntu 20.04+ / CentOS 8+
- Node.js 16+
- 至少 1GB 内存

#### 部署脚本
```bash
#!/bin/bash
# deploy.sh

# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装 Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 克隆项目
git clone https://github.com/your-username/ez-theme-builder.git
cd ez-theme-builder

# 设置环境变量
export NODE_OPTIONS="--max-old-space-size=256"
export NODE_ENV="production"

# 安装依赖
npm install
cd frontend && npm install && npm run build
cd ..

# 运行轻量级构建
npm run lightweight-build

# 使用 PM2 启动
npm install -g pm2
pm2 start server.js --name "ez-theme-builder"
pm2 startup
pm2 save
```

### 2. 腾讯云 CVM

#### 使用宝塔面板
1. 安装宝塔面板
2. 安装 Node.js 管理器
3. 上传项目文件
4. 设置环境变量
5. 运行轻量级构建

#### 手动部署
```bash
# 安装 Node.js
wget https://nodejs.org/dist/v18.17.0/node-v18.17.0-linux-x64.tar.xz
tar -xf node-v18.17.0-linux-x64.tar.xz
sudo mv node-v18.17.0-linux-x64 /usr/local/node

# 设置环境变量
echo 'export PATH=/usr/local/node/bin:$PATH' >> ~/.bashrc
echo 'export NODE_OPTIONS="--max-old-space-size=256"' >> ~/.bashrc
source ~/.bashrc

# 部署项目
git clone https://github.com/your-username/ez-theme-builder.git
cd ez-theme-builder
npm install
cd frontend && npm install && npm run build
cd ..
npm run lightweight-build
npm start
```

### 3. AWS EC2

#### 使用 AWS CLI
```bash
# 创建 EC2 实例
aws ec2 run-instances \
  --image-id ami-0c02fb55956c7d316 \
  --count 1 \
  --instance-type t2.micro \
  --key-name your-key-pair \
  --security-group-ids sg-xxxxxxxxx

# 连接到实例
ssh -i your-key.pem ubuntu@your-instance-ip

# 部署项目
git clone https://github.com/your-username/ez-theme-builder.git
cd ez-theme-builder
export NODE_OPTIONS="--max-old-space-size=256"
npm install
cd frontend && npm install && npm run build
cd ..
npm run lightweight-build
npm start
```

## 监控和维护

### 1. 进程管理

#### 使用 PM2
```bash
# 安装 PM2
npm install -g pm2

# 启动应用
pm2 start server.js --name "ez-theme-builder"

# 设置开机自启
pm2 startup
pm2 save

# 监控
pm2 monit
pm2 logs
```

#### 使用 systemd
```ini
# /etc/systemd/system/ez-theme-builder.service
[Unit]
Description=EZ-Theme Builder
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/ez-theme-builder
Environment=NODE_OPTIONS=--max-old-space-size=256
Environment=NODE_ENV=production
ExecStart=/usr/bin/node server.js
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### 2. 日志管理

#### 配置日志轮转
```bash
# /etc/logrotate.d/ez-theme-builder
/home/ubuntu/ez-theme-builder/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
}
```

### 3. 性能监控

#### 使用 htop
```bash
# 安装 htop
sudo apt install htop

# 监控系统资源
htop
```

#### 使用 Node.js 内置监控
```javascript
// 在 server.js 中添加
const os = require('os');

setInterval(() => {
  const memUsage = process.memoryUsage();
  const cpuUsage = process.cpuUsage();
  
  console.log('Memory Usage:', {
    rss: Math.round(memUsage.rss / 1024 / 1024) + 'MB',
    heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024) + 'MB',
    heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024) + 'MB'
  });
}, 60000);
```

## 故障排除

### 常见问题

#### 1. 内存不足
```bash
# 解决方案
export NODE_OPTIONS="--max-old-space-size=128"
npm run lightweight-build
```

#### 2. 端口被占用
```bash
# 检查端口
netstat -tulpn | grep :3000

# 杀死进程
sudo kill -9 <PID>
```

#### 3. 权限问题
```bash
# 修复权限
sudo chown -R $USER:$USER /path/to/project
chmod +x deploy.sh
```

#### 4. 依赖安装失败
```bash
# 清理缓存
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

## 最佳实践

### 1. 安全配置
- 使用强密码和 JWT_SECRET
- 配置防火墙
- 定期更新依赖
- 使用 HTTPS

### 2. 性能优化
- 启用 gzip 压缩
- 使用 CDN
- 配置缓存
- 监控内存使用

### 3. 备份策略
- 定期备份数据库
- 备份构建文件
- 使用版本控制
- 配置自动备份

## 更新日志

### v1.3.0
- 添加通用部署指南
- 支持多种服务器平台
- 优化内存配置
- 添加监控和维护指南
