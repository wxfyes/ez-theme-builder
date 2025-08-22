# EZ-Theme 自动打包系统

一个基于Web的EZ-Theme主题自动构建系统，支持用户自定义配置、在线打包、支付系统和API接口。

## 功能特性

### 🎨 主题构建
- 可视化配置编辑器
- 支持V2board、Xiao-V2board、Xboard面板
- 实时预览配置效果
- 一键生成主题包

### 💳 支付系统
- 支持支付宝、微信、PayPal
- 积分充值系统
- 订单管理
- 支付状态监控

### 🔐 用户系统
- 用户注册/登录
- API密钥管理
- 构建历史记录
- 个人资料管理

### 🛡️ 安全特性
- JWT身份验证
- API密钥验证
- 速率限制
- 输入验证

### 📊 管理后台
- 系统配置管理
- 用户管理
- 构建统计
- 系统监控

## 技术栈

### 后端
- **Node.js** - 运行环境
- **Express** - Web框架
- **SQLite** - 数据库
- **JWT** - 身份验证
- **bcryptjs** - 密码加密
- **archiver** - 文件打包

### 前端
- **Vue 3** - 前端框架
- **Vue Router** - 路由管理
- **Pinia** - 状态管理
- **Element Plus** - UI组件库
- **Vite** - 构建工具

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
```

### 配置EZ-Theme路径

在 `server.js` 中修改EZ-Theme项目路径：

```javascript
// 复制EZ-Theme项目文件
const ezThemePath = 'E:\\GitHub\\EZ-Theme'; // 修改为您的路径
```

### 启动服务

```bash
# 开发模式
npm run dev

# 生产模式
npm start
```

### 构建前端

```bash
# 构建前端
npm run build
```

## 默认账户

- **管理员账户**
  - 用户名: `admin`
  - 密码: `admin123`
  - 邮箱: `admin@example.com`

## API接口

### 认证接口
- `POST /api/auth/register` - 用户注册
- `POST /api/auth/login` - 用户登录

### 构建接口
- `POST /api/builds/create` - 创建构建（需要登录）
- `POST /api/builds/create-with-key` - 创建构建（API密钥）
- `GET /api/builds/:buildId` - 获取构建状态
- `GET /api/builds/:buildId/download` - 下载构建文件

### 支付接口
- `POST /api/orders/create` - 创建订单
- `GET /api/orders/:orderId/status` - 查询订单状态
- `POST /api/orders/:orderId/pay` - 支付订单

### 管理接口
- `GET /api/admin/users` - 获取用户列表
- `PUT /api/admin/users/:id` - 更新用户信息
- `DELETE /api/admin/users/:id` - 删除用户
- `POST /api/admin/config` - 更新系统配置

## 部署说明

### 宝塔面板部署

1. 上传项目文件到服务器
2. 安装Node.js环境
3. 在项目目录执行：
   ```bash
   npm install
   npm run build
   npm start
   ```
4. 配置反向代理到3000端口
5. 配置SSL证书

### Docker部署

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

EXPOSE 3000

CMD ["npm", "start"]
```

## 配置说明

### 系统配置
- `price_per_build` - 每次构建费用（积分）
- `max_builds_per_day` - 每日构建限制
- `payment_methods` - 支持的支付方式
- `license_key` - 系统授权密钥

### 环境变量
- `PORT` - 服务端口（默认3000）
- `JWT_SECRET` - JWT密钥
- `NODE_ENV` - 运行环境

## 商业功能

### 支付集成
系统预留了支付接口，可以集成：
- 支付宝支付
- 微信支付
- PayPal
- 其他第三方支付

### 授权系统
- API密钥验证
- 用户权限管理
- 构建次数限制
- 余额系统

## 开发说明

### 目录结构
```
├── server.js              # 后端主文件
├── package.json           # 后端依赖
├── frontend/              # 前端项目
│   ├── src/
│   │   ├── views/         # 页面组件
│   │   ├── stores/        # 状态管理
│   │   └── router/        # 路由配置
│   ├── package.json       # 前端依赖
│   └── vite.config.js     # Vite配置
├── builds/                # 构建输出目录
├── temp/                  # 临时文件目录
└── database.sqlite        # 数据库文件
```

### 自定义开发
1. 修改EZ-Theme配置模板
2. 添加新的支付方式
3. 扩展管理功能
4. 自定义主题样式

## 许可证

MIT License

## 支持

如有问题，请提交Issue或联系开发者。

---

**注意**: 请确保您有合法的EZ-Theme使用权限，本系统仅用于学习和合法用途。
