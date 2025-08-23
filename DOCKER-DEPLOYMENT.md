# Docker 部署指南

## 🐳 **Docker 部署优势**

使用 Docker 部署 EZ-Theme Builder 有以下优势：

- ✅ **环境隔离**：避免系统依赖冲突
- ✅ **一致性**：在任何系统上运行结果一致
- ✅ **简单部署**：一键部署，无需复杂配置
- ✅ **易于管理**：容器化管理，方便更新和维护
- ✅ **资源隔离**：不影响系统其他服务

## 🛠️ **系统要求**

- **操作系统**：Ubuntu 18.04+, Debian 9+, CentOS 7+
- **内存**：至少 1GB RAM
- **磁盘空间**：至少 2GB 可用空间
- **网络**：需要互联网连接下载镜像

## 🚀 **快速部署**

### 方法一：一键部署脚本（推荐）

```bash
# 下载部署脚本
wget -O deploy-docker.sh https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/deploy-docker.sh

# 给脚本执行权限
chmod +x deploy-docker.sh

# 运行部署脚本
./deploy-docker.sh
```

### 方法二：手动部署

#### 1. 安装 Docker

**Ubuntu/Debian:**
```bash
# 更新包列表
apt-get update

# 安装依赖
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# 添加Docker官方GPG密钥
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 添加Docker仓库
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# 启动Docker服务
systemctl start docker
systemctl enable docker
```

**CentOS/Red Hat:**
```bash
# 安装依赖
yum install -y yum-utils

# 添加Docker仓库
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 安装Docker
yum install -y docker-ce docker-ce-cli containerd.io

# 启动Docker服务
systemctl start docker
systemctl enable docker
```

#### 2. 安装 Docker Compose

```bash
# 下载Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 设置执行权限
chmod +x /usr/local/bin/docker-compose

# 验证安装
docker-compose --version
```

#### 3. 下载项目文件

```bash
# 创建项目目录
mkdir -p /www/wwwroot/ez-theme-builder
cd /www/wwwroot/ez-theme-builder

# 下载项目
wget -O ez-theme-builder.zip https://github.com/wxfyes/ez-theme-builder/archive/refs/heads/main.zip

# 解压文件
unzip ez-theme-builder.zip
mv ez-theme-builder-main/* .
rm -rf ez-theme-builder-main ez-theme-builder.zip
```

#### 4. 构建和运行

```bash
# 构建镜像
docker-compose build --no-cache

# 启动容器
docker-compose up -d

# 查看状态
docker-compose ps
```

## 📊 **管理命令**

### 基本管理

```bash
# 查看容器状态
docker-compose ps

# 查看日志
docker-compose logs

# 实时查看日志
docker-compose logs -f

# 启动应用
docker-compose up -d

# 停止应用
docker-compose down

# 重启应用
docker-compose restart

# 重新构建并启动
docker-compose up -d --build
```

### 使用管理脚本

部署完成后，会自动创建以下管理脚本：

```bash
# 启动应用
./start.sh

# 停止应用
./stop.sh

# 重启应用
./restart.sh

# 查看日志
./logs.sh

# 更新应用
./update.sh

# 删除应用
./remove.sh
```

## 🔧 **配置说明**

### Dockerfile 配置

```dockerfile
# 使用Node.js 18 Alpine镜像
FROM node:18-alpine

# 安装系统依赖
RUN apk add --no-cache git python3 make g++ wget curl

# 设置工作目录
WORKDIR /app

# 安装依赖并构建
COPY package*.json ./
COPY frontend/package*.json ./frontend/
RUN npm ci --only=production
WORKDIR /app/frontend
RUN npm ci --only=production
WORKDIR /app
COPY . .
RUN npm run build

# 创建必要目录
RUN mkdir -p logs builds temp data

# 暴露端口
EXPOSE 3000

# 启动命令
CMD ["node", "server.js"]
```

### docker-compose.yml 配置

```yaml
version: '3.8'

services:
  ez-theme-builder:
    build: .
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
```

## 🌐 **访问地址**

部署完成后，可以通过以下地址访问：

- **用户界面**: `http://你的服务器IP:3000`
- **管理后台**: `http://你的服务器IP:3000/admin`
- **API文档**: `http://你的服务器IP:3000/api/health`

## 🔍 **故障排除**

### 常见问题

#### 1. 端口被占用

```bash
# 查看端口占用
netstat -tulpn | grep :3000

# 修改端口（编辑docker-compose.yml）
ports:
  - "8080:3000"  # 改为8080端口
```

#### 2. 内存不足

```bash
# 增加内存限制（编辑docker-compose.yml）
environment:
  - NODE_OPTIONS=--max-old-space-size=256  # 减少内存使用
```

#### 3. 构建失败

```bash
# 清理Docker缓存
docker system prune -f

# 重新构建
docker-compose build --no-cache
```

#### 4. 容器无法启动

```bash
# 查看详细日志
docker-compose logs

# 检查配置文件
docker-compose config

# 重新创建容器
docker-compose down
docker-compose up -d
```

### 日志查看

```bash
# 查看应用日志
docker-compose logs ez-theme-builder

# 查看实时日志
docker-compose logs -f ez-theme-builder

# 查看错误日志
docker-compose logs ez-theme-builder 2>&1 | grep ERROR
```

## 🔄 **更新部署**

### 自动更新

```bash
# 使用更新脚本
./update.sh

# 或手动更新
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### 手动更新

```bash
# 停止容器
docker-compose down

# 拉取最新代码
git pull origin main

# 重新构建
docker-compose build --no-cache

# 启动容器
docker-compose up -d
```

## 🗑️ **删除部署**

### 完全删除

```bash
# 使用删除脚本
./remove.sh

# 或手动删除
docker-compose down
docker system prune -f
rm -rf /www/wwwroot/ez-theme-builder
```

### 保留数据删除

```bash
# 只删除容器，保留数据
docker-compose down

# 删除镜像
docker rmi ez-theme-builder_ez-theme-builder
```

## 📈 **性能优化**

### 资源限制

```yaml
# 在docker-compose.yml中添加资源限制
services:
  ez-theme-builder:
    # ... 其他配置
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'
```

### 数据卷优化

```yaml
# 使用命名卷而不是绑定挂载
volumes:
  - ez-theme-logs:/app/logs
  - ez-theme-builds:/app/builds
  - ez-theme-data:/app/data

volumes:
  ez-theme-logs:
  ez-theme-builds:
  ez-theme-data:
```

## 🔒 **安全配置**

### 环境变量

```bash
# 设置安全的JWT密钥
export JWT_SECRET="your-very-secure-secret-key"

# 在docker-compose.yml中使用
environment:
  - JWT_SECRET=${JWT_SECRET}
```

### 网络安全

```yaml
# 使用自定义网络
networks:
  ez-theme-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

## 📋 **部署检查清单**

- [ ] Docker 已安装并运行
- [ ] Docker Compose 已安装
- [ ] 项目文件已下载
- [ ] 容器已构建成功
- [ ] 容器已启动并运行
- [ ] 端口 3000 可访问
- [ ] 管理脚本已创建
- [ ] 日志正常输出
- [ ] 用户界面可访问
- [ ] 管理后台可访问

## 🎯 **优势总结**

相比传统部署方式，Docker 部署具有以下优势：

1. **环境一致性**：避免"在我机器上能运行"的问题
2. **快速部署**：一键部署，无需复杂配置
3. **易于维护**：容器化管理，更新简单
4. **资源隔离**：不影响系统其他服务
5. **可移植性**：可在任何支持 Docker 的系统上运行
6. **版本控制**：镜像版本管理，便于回滚

## 📞 **技术支持**

如果遇到问题：

1. 查看容器日志：`docker-compose logs`
2. 检查容器状态：`docker-compose ps`
3. 验证配置文件：`docker-compose config`
4. 清理并重新构建：`docker system prune -f && docker-compose build --no-cache`

Docker 部署是最稳定可靠的部署方式，强烈推荐使用！
