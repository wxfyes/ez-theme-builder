# EZ-Theme Builder

一个用于构建和自定义EZ-Theme主题的Web应用。

## 功能特性

- 🎨 **主题构建器** - 可视化配置EZ-Theme主题
- 🔧 **多URL支持** - 支持配置多个API地址
- 🖼️ **Logo替换** - 支持上传自定义Logo
- ⚙️ **配置管理** - 完整的主题配置选项
- 📦 **一键打包** - 自动生成可部署的主题包
- 👥 **用户系统** - 用户注册、登录、积分管理
- 💳 **支付系统** - 支持多种支付方式
- 🔐 **管理后台** - 完整的后台管理系统

## 技术栈

### 后端
- **Node.js** - 服务器运行环境
- **Express.js** - Web框架
- **SQLite** - 数据库
- **JWT** - 身份认证
- **Multer** - 文件上传
- **Archiver** - ZIP文件打包

### 前端
- **Vue.js 3** - 前端框架
- **Element Plus** - UI组件库
- **Vite** - 构建工具
- **Pinia** - 状态管理
- **Vue Router** - 路由管理
- **Axios** - HTTP客户端

## 快速开始

### 环境要求
- Node.js >= 16.0.0
- npm >= 8.0.0

### 安装依赖
```bash
# 安装后端依赖
npm install

# 安装前端依赖
cd frontend
npm install
cd ..
```

### 初始化数据库
```bash
# 启动服务器，数据库会自动初始化
npm start
```

### 准备基础构建
```bash
# 克隆并构建EZ-Theme基础项目
npm run prepare-base
```

### 启动开发服务器
```bash
# 启动后端服务器
npm run dev

# 在另一个终端启动前端开发服务器
cd frontend
npm run dev
```

### 构建生产版本
```bash
# 构建前端
cd frontend
npm run build
cd ..

# 启动生产服务器
npm start
```

## 配置说明

### 环境变量
创建 `.env` 文件：
```env
PORT=3000
JWT_SECRET=your-jwt-secret
NODE_ENV=production
```

### 默认管理员账户
- 用户名：`admin`
- 密码：`admin123`

## 使用说明

### 1. 用户注册/登录
- 访问应用首页进行注册
- 登录后可以开始构建主题

### 2. 主题构建
- 在"主题构建"页面配置主题参数
- 支持配置网站信息、API设置、功能开关等
- 可以上传自定义Logo
- 支持配置多个API地址

### 3. 构建主题
- 配置完成后点击"开始构建"
- 系统会自动生成主题包
- 构建完成后可以下载ZIP文件

### 4. 部署主题
- 解压下载的ZIP文件
- 将文件上传到Web服务器
- 配置服务器指向正确的API地址

## 项目结构

```
ez-theme-builder/
├── frontend/                 # 前端代码
│   ├── src/
│   │   ├── views/           # 页面组件
│   │   ├── stores/          # 状态管理
│   │   ├── router/          # 路由配置
│   │   └── assets/          # 静态资源
│   └── dist/                # 构建输出
├── base-build/              # EZ-Theme基础项目
├── builds/                  # 构建输出目录
├── temp/                    # 临时文件目录
├── server.js               # 后端主文件
├── config-template.js      # 配置模板
├── package.json            # 项目配置
└── README.md               # 项目说明
```

## API文档

### 用户相关
- `POST /api/auth/register` - 用户注册
- `POST /api/auth/login` - 用户登录
- `GET /api/auth/profile` - 获取用户信息

### 构建相关
- `POST /api/builds/create` - 创建构建任务
- `GET /api/builds/:buildId` - 获取构建状态
- `GET /api/builds/:buildId/download` - 下载构建结果

### 系统相关
- `GET /api/system/config` - 获取系统配置
- `POST /api/admin/config` - 更新系统配置

## 部署

### 使用Docker
```bash
# 构建镜像
docker build -t ez-theme-builder .

# 运行容器
docker run -p 3000:3000 ez-theme-builder
```

### 使用PM2
```bash
# 安装PM2
npm install -g pm2

# 启动应用
pm2 start server.js --name ez-theme-builder

# 设置开机自启
pm2 startup
pm2 save
```

## 贡献

欢迎提交Issue和Pull Request！

## 许可证

MIT License

## 更新日志

### v1.0.0
- 初始版本发布
- 支持基础主题构建功能
- 支持Logo上传和替换
- 支持多URL配置
- 完整的用户管理系统
