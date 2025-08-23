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

### 方法一：使用Docker部署（强烈推荐）

如果遇到构建工具问题，强烈推荐使用 Docker 部署：

```bash
# 下载Docker部署脚本
wget -O deploy-docker.sh https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/deploy-docker.sh

# 给脚本执行权限
chmod +x deploy-docker.sh

# 运行Docker部署脚本
./deploy-docker.sh
```

**Docker部署优势：**
- ✅ 避免系统依赖冲突
- ✅ 环境隔离，不影响系统
- ✅ 一键部署，无需复杂配置
- ✅ 易于管理和更新

### 方法二：使用自动部署脚本（传统方式）

```bash
# 下载部署脚本
wget https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/deploy-baota.sh

# 给脚本执行权限
chmod +x deploy-baota.sh

# 运行部署脚本
./deploy-baota.sh
```

### 方法二：使用一键删除脚本

```bash
# 下载删除脚本
wget https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/remove-baota.sh

# 给脚本执行权限
chmod +x remove-baota.sh

# 运行删除脚本
./remove-baota.sh
```

### 方法三：快速删除（紧急情况）

```bash
# 下载快速删除脚本
wget https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/quick-remove.sh

# 给脚本执行权限
chmod +x quick-remove.sh

# 运行快速删除脚本
./quick-remove.sh
```

### 方法四：Git仓库修复（解决Git问题）

如果遇到 `fatal: not a git repository` 错误：

```bash
# 下载Git修复脚本
wget https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/fix-git-issue.sh

# 给脚本执行权限
chmod +x fix-git-issue.sh

# 运行Git修复脚本
./fix-git-issue.sh
```

### 方法五：直接下载部署（不依赖Git）

如果Git有问题，可以直接下载ZIP文件：

```bash
# 下载直接部署脚本
wget https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/download-direct.sh

# 给脚本执行权限
chmod +x download-direct.sh

# 运行直接部署脚本
./download-direct.sh
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

### 3. Git相关问题

#### Git仓库错误
如果遇到 `fatal: not a git repository` 错误：

```bash
# 方法1：使用Git修复脚本
wget https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/fix-git-issue.sh
chmod +x fix-git-issue.sh
./fix-git-issue.sh

# 方法2：直接下载部署（推荐）
wget https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/download-direct.sh
chmod +x download-direct.sh
./download-direct.sh
```

### 4. 构建工具问题

#### 构建工具错误
如果遇到 `vue-cli-service: command not found` 或 `vite: command not found` 错误：

```bash
# 方法1：使用标准修复脚本
wget https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/quick-fix.sh
chmod +x quick-fix.sh
./quick-fix.sh

# 方法2：使用安全修复脚本（推荐，避免EEXIST错误）
wget https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/quick-fix-safe.sh
chmod +x quick-fix-safe.sh
./quick-fix-safe.sh

# 方法3：使用终极修复脚本（推荐，处理所有构建问题）
# 一键下载、设置权限并运行
wget -O quick-fix-ultimate.sh https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/quick-fix-ultimate.sh && chmod +x quick-fix-ultimate.sh && ./quick-fix-ultimate.sh

# 方法4：使用诊断脚本（先诊断问题）
wget -O diagnose-build.sh https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/diagnose-build.sh && chmod +x diagnose-build.sh && ./diagnose-build.sh

# 方法5：使用依赖冲突修复脚本（解决ERESOLVE错误）
wget -O fix-dependency-conflict.sh https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/fix-dependency-conflict.sh && chmod +x fix-dependency-conflict.sh && ./fix-dependency-conflict.sh

# 方法6：使用Debian 11专用修复脚本（推荐Debian系统使用）
wget -O fix-debian-build.sh https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/fix-debian-build.sh && chmod +x fix-debian-build.sh && ./fix-debian-build.sh

# 方法7：使用缺失vite包修复脚本（解决vite包未安装问题）
wget -O fix-missing-vite.sh https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/fix-missing-vite.sh && chmod +x fix-missing-vite.sh && ./fix-missing-vite.sh
```

**注意**：
- 如果遇到 `EEXIST: file already exists` 错误，请使用 `quick-fix-safe.sh` 脚本
- 如果遇到 `No such file or directory` 错误（如 `./node_modules/.bin/vite: No such file or directory`），请使用 `quick-fix-ultimate.sh` 脚本
- 如果遇到 `ERESOLVE unable to resolve dependency tree` 错误，请使用 `fix-dependency-conflict.sh` 脚本
- **Debian 11 系统用户**：推荐使用 `fix-debian-build.sh` 脚本，专门处理Debian系统的构建问题
- **vite包缺失问题**：如果诊断显示 `vite包不存在`，请使用 `fix-missing-vite.sh` 脚本
- 终极修复脚本会尝试多种构建方法，包括npx、本地路径、npm run build和直接node调用

#### Git下载失败
如果Git克隆或拉取失败：

```bash
# 检查网络连接
ping github.com

# 尝试使用备用下载方式
wget https://raw.githubusercontent.com/wxfyes/ez-theme-builder/main/download-direct.sh
chmod +x download-direct.sh
./download-direct.sh
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

## 🗑️ **删除和清理**

### 完整删除脚本

`remove-baota.sh` 提供完整的删除功能：

- ✅ 停止并删除PM2进程
- ✅ 删除项目目录和所有文件
- ✅ 清理临时目录
- ✅ 清理npm缓存
- ✅ 清理系统日志
- ✅ 清理环境变量
- ✅ 可选删除全局Node.js模块
- ✅ 可选删除数据库文件
- ✅ 提供宝塔面板配置清理指导

### 快速删除脚本

`quick-remove.sh` 用于紧急情况：

- ⚡ 快速停止PM2进程
- ⚡ 快速删除项目目录
- ⚡ 快速清理临时文件
- ⚡ 快速清理npm缓存

### 使用建议

1. **正常删除**：使用 `remove-baota.sh`
2. **紧急删除**：使用 `quick-remove.sh`
3. **重新部署**：删除后运行 `deploy-baota.sh`

## 更新日志

### v1.6.0
- 添加一键删除脚本
- 添加快速删除脚本
- 完善删除和清理功能
- 优化脚本安全性

### v1.5.0
- 添加宝塔面板部署指南
- 创建自动部署脚本
- 优化内存配置
- 添加故障排除指南
