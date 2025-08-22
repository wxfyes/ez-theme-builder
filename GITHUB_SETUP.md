# GitHub仓库配置说明

## 环境变量配置

在项目根目录创建 `.env` 文件，添加以下配置：

```bash
# 服务器配置
PORT=3000
JWT_SECRET=your-secret-key
NODE_ENV=development

# EZ-Theme GitHub仓库配置
EZ_THEME_REPO=https://github.com/your-username/EZ-Theme.git
EZ_THEME_BRANCH=main

# 其他配置
PRICE_PER_BUILD=10
MAX_BUILDS_PER_DAY=5
```

## 配置说明

### EZ_THEME_REPO
- **说明**: EZ-Theme项目的GitHub仓库地址
- **格式**: `https://github.com/用户名/仓库名.git`
- **示例**: `https://github.com/your-username/EZ-Theme.git`

### EZ_THEME_BRANCH
- **说明**: 要拉取的分支名称
- **默认值**: `main`
- **可选值**: `main`, `master`, `develop` 等

## 使用步骤

1. **配置环境变量**：
   ```bash
   # 复制示例配置
   cp .env.example .env
   
   # 编辑配置文件
   nano .env
   ```

2. **修改仓库地址**：
   - 将 `your-username` 替换为你的GitHub用户名
   - 将 `EZ-Theme` 替换为你的仓库名
   - 确保仓库是公开的，或者配置SSH密钥

3. **重启服务器**：
   ```bash
   npm run dev
   ```

## 注意事项

1. **仓库权限**：确保仓库是公开的，或者服务器有访问权限
2. **网络连接**：服务器需要能够访问GitHub
3. **Git版本**：确保服务器已安装Git
4. **分支名称**：确保指定的分支存在

## 故障排除

### 如果拉取失败：
1. 检查仓库地址是否正确
2. 确认仓库是公开的
3. 检查网络连接
4. 查看服务器日志

### 如果依赖安装失败：
1. 检查 `package.json` 是否存在
2. 确认Node.js版本兼容
3. 检查npm配置
