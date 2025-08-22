# Vercel 部署指南

## Vercel 内存配置

### 🆓 **免费计划 (Hobby)**
- **构建内存**: 1024MB (1GB)
- **函数内存**: 1024MB (1GB)
- **推荐设置**: `--max-old-space-size=512`

### 💰 **付费计划 (Pro)**
- **构建内存**: 2048MB (2GB)
- **函数内存**: 1024MB (1GB)
- **推荐设置**: `--max-old-space-size=1024`

### 🏢 **企业计划 (Enterprise)**
- **构建内存**: 4096MB (4GB)
- **函数内存**: 3008MB (3GB)
- **推荐设置**: `--max-old-space-size=2048`

## 部署步骤

### 1. 安装 Vercel CLI

```bash
npm install -g vercel
```

### 2. 登录 Vercel

```bash
vercel login
```

### 3. 配置项目

确保项目根目录包含以下文件：

#### vercel.json
```json
{
  "version": 2,
  "name": "ez-theme-builder",
  "builds": [
    {
      "src": "server.js",
      "use": "@vercel/node",
      "config": {
        "maxLambdaSize": "50mb"
      }
    }
  ],
  "routes": [
    {
      "src": "/api/(.*)",
      "dest": "/server.js"
    },
    {
      "src": "/(.*)",
      "dest": "/server.js"
    }
  ],
  "env": {
    "NODE_ENV": "production",
    "NODE_OPTIONS": "--max-old-space-size=512"
  },
  "functions": {
    "server.js": {
      "maxDuration": 30
    }
  }
}
```

### 4. 设置环境变量

```bash
vercel env add JWT_SECRET
vercel env add NODE_ENV production
vercel env add NODE_OPTIONS --max-old-space-size=512
```

### 5. 部署项目

```bash
# 首次部署
vercel

# 生产环境部署
vercel --prod
```

## 构建优化

### 使用 Vercel 专用构建

```bash
npm run vercel-build
```

### 构建特点

1. **内存优化**: 使用512MB内存限制
2. **依赖优化**: 只安装必要的依赖
3. **文件优化**: 只复制必要文件
4. **缓存优化**: 利用Vercel的构建缓存

## 环境变量配置

### 必需环境变量

```bash
JWT_SECRET=your-secret-key
NODE_ENV=production
NODE_OPTIONS=--max-old-space-size=512
```

### 可选环境变量

```bash
PORT=3000
VUE_APP_CONFIGJS=false
```

## 性能优化

### 1. 内存使用优化

```javascript
// 在 server.js 中添加内存监控
const os = require('os');

setInterval(() => {
  const memUsage = process.memoryUsage();
  console.log('Memory Usage:', {
    rss: Math.round(memUsage.rss / 1024 / 1024) + 'MB',
    heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024) + 'MB',
    heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024) + 'MB'
  });
}, 60000);
```

### 2. 函数超时优化

```json
{
  "functions": {
    "server.js": {
      "maxDuration": 30
    }
  }
}
```

### 3. 文件大小优化

```json
{
  "builds": [
    {
      "src": "server.js",
      "use": "@vercel/node",
      "config": {
        "maxLambdaSize": "50mb"
      }
    }
  ]
}
```

## 监控和日志

### 查看部署日志

```bash
vercel logs
```

### 查看函数日志

```bash
vercel logs --function=server.js
```

### 实时监控

```bash
vercel logs --follow
```

## 故障排除

### 常见问题

#### 1. 内存不足
```bash
# 解决方案：减少内存使用
export NODE_OPTIONS="--max-old-space-size=256"
```

#### 2. 函数超时
```json
{
  "functions": {
    "server.js": {
      "maxDuration": 60
    }
  }
}
```

#### 3. 文件大小超限
```bash
# 清理不必要的文件
rm -rf node_modules
rm -rf .git
rm -rf temp
```

#### 4. 构建失败
```bash
# 清理缓存重新构建
vercel --force
```

## 最佳实践

### 1. 内存管理
- 使用512MB内存限制（免费计划）
- 监控内存使用情况
- 及时清理不需要的对象

### 2. 依赖管理
- 只安装必要的依赖
- 使用 `npm ci` 而不是 `npm install`
- 定期更新依赖

### 3. 文件优化
- 只复制必要的文件
- 使用 `.vercelignore` 排除文件
- 压缩静态资源

### 4. 缓存策略
- 利用Vercel的构建缓存
- 使用CDN加速
- 配置适当的缓存头

## 升级到付费计划

### 何时升级

1. **内存不足**: 构建时经常出现内存错误
2. **函数超时**: 构建时间超过30秒
3. **文件大小**: 项目大小超过50MB
4. **流量增加**: 月访问量超过100GB

### 升级步骤

1. 访问 [Vercel Dashboard](https://vercel.com/dashboard)
2. 选择 Pro 或 Enterprise 计划
3. 更新 `vercel.json` 配置
4. 重新部署项目

## 更新日志

### v1.4.0
- 添加Vercel专用构建脚本
- 优化内存使用配置
- 添加Vercel部署指南
- 支持免费和付费计划
