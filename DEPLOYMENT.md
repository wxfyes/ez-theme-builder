# 部署指南

## 🚀 免费平台部署

### 1. Render (推荐)

**优点**: 部署简单、自动HTTPS、免费数据库
**限制**: 免费版15分钟无请求会休眠

#### 部署步骤:

1. **注册账户**
   - 访问 https://render.com
   - 使用GitHub账户登录

2. **创建Web Service**
   - 点击 "New +" → "Web Service"
   - 连接你的GitHub仓库

3. **配置设置**
   ```
   Name: ez-theme-builder
   Environment: Node
   Build Command: npm install && cd frontend && npm install && npm run build && cd .. && npm run prepare-base
   Start Command: npm start
   ```

4. **环境变量**
   ```
   NODE_ENV=production
   JWT_SECRET=your-secret-key-here
   ```
   
   **注意**: Render会自动设置PORT环境变量，无需手动配置

5. **点击 "Create Web Service"**

### 2. Railway

**优点**: 支持Node.js、自动部署、免费数据库
**限制**: 免费版每月$5额度

#### 部署步骤:

1. **注册账户**
   - 访问 https://railway.app
   - 使用GitHub账户登录

2. **部署项目**
   - 点击 "New Project" → "Deploy from GitHub repo"
   - 选择你的仓库

3. **自动配置**
   - Railway会自动检测配置
   - 使用 `railway.json` 文件

### 3. Fly.io

**优点**: 全球部署、支持Docker、免费额度
**限制**: 免费版3个应用、256MB内存

#### 部署步骤:

1. **安装CLI**
   ```bash
   # Windows
   powershell -Command "iwr https://fly.io/install.ps1 -useb | iex"
   
   # macOS/Linux
   curl -L https://fly.io/install.sh | sh
   ```

2. **登录和部署**
   ```bash
   fly auth login
   fly launch
   fly deploy
   ```

## 🔧 本地部署

### 使用Docker

```bash
# 构建镜像
docker build -t ez-theme-builder .

# 运行容器
docker run -p 3000:3000 ez-theme-builder
```

### 使用Docker Compose

```bash
# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f
```

### 使用PM2

```bash
# 安装PM2
npm install -g pm2

# 启动应用
pm2 start ecosystem.config.js --env production

# 设置开机自启
pm2 startup
pm2 save
```

## 📋 部署检查清单

### 部署前检查:
- [ ] 所有依赖已安装
- [ ] 前端已构建 (`npm run build`)
- [ ] 基础构建已准备 (`npm run prepare-base`)
- [ ] 环境变量已配置
- [ ] 数据库已初始化

### 部署后检查:
- [ ] 应用可以访问
- [ ] 健康检查通过 (`/api/health`)
- [ ] 用户注册/登录正常
- [ ] 主题构建功能正常
- [ ] 文件上传功能正常

## 🛠️ 故障排除

### 常见问题:

1. **构建失败**
   - 检查Node.js版本 (需要 >= 16.0.0)
   - 检查依赖安装是否完整
   - 查看构建日志

2. **应用无法启动**
   - 检查端口是否被占用
   - 检查环境变量配置
   - 查看错误日志

3. **数据库问题**
   - 检查数据库文件权限
   - 确保数据库目录可写
   - 重新初始化数据库

4. **文件上传失败**
   - 检查临时目录权限
   - 检查磁盘空间
   - 验证文件大小限制

## 📞 支持

如果遇到部署问题，请:
1. 查看平台日志
2. 检查应用日志
3. 提交Issue到GitHub仓库
