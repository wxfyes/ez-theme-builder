# GitHub Actions 自动构建设置

## 🎯 **概述**

使用 GitHub Actions 在云端自动构建主题，避免本地服务器资源不足的问题。

## 📋 **设置步骤**

### 1. **推送代码到 GitHub**

```bash
# 确保 .github/workflows/build-theme.yml 文件已创建
git add .
git commit -m "Add GitHub Actions workflow"
git push origin main
```

### 2. **设置 GitHub Token**

1. **生成 Personal Access Token**
   - 进入 GitHub Settings → Developer settings → Personal access tokens
   - 点击 "Generate new token"
   - 选择 "repo" 权限
   - 复制生成的 token

2. **在服务器上设置环境变量**
   ```bash
   # 在服务器上设置
   export GITHUB_TOKEN="your_github_token_here"
   
   # 或者添加到 .env 文件
   echo "GITHUB_TOKEN=your_github_token_here" >> .env
   ```

### 3. **安装依赖**

```bash
# 在服务器上安装 axios
npm install axios
```

## 🚀 **使用方法**

### **方法一：手动触发构建**

1. **进入 GitHub 仓库**
2. **点击 Actions 标签**
3. **选择 "Build EZ Theme" 工作流**
4. **点击 "Run workflow"**
5. **填写构建参数**：
   - Panel Type: 选择面板类型
   - Site Name: 网站名称
   - Site Description: 网站描述
   - API URL: API 地址
6. **点击 "Run workflow"**

### **方法二：通过 API 触发**

```bash
# 发送构建请求
curl -X POST http://your-server:3000/api/build/github-actions \
  -H "Content-Type: application/json" \
  -d '{
    "panel_type": "Xiao-V2board",
    "site_name": "My Theme",
    "site_description": "我的主题",
    "api_url": "https://my-panel.com"
  }'
```

### **方法三：下载最新构建**

```bash
# 获取最新构建信息
curl http://your-server:3000/api/download/latest

# 下载构建文件
wget $(curl -s http://your-server:3000/api/download/latest | jq -r '.download_url')
```

## 📁 **构建结果**

构建完成后，你可以：

1. **从 GitHub Releases 下载**
   - 进入仓库的 Releases 页面
   - 下载 `theme-build.zip` 文件

2. **解压到网站目录**
   ```bash
   unzip theme-build.zip -d /path/to/your/website/
   ```

## 🔧 **故障排除**

### **1. 权限问题**
```bash
# 检查 GitHub Token 是否正确
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user
```

### **2. 工作流失败**
- 检查 GitHub Actions 日志
- 确保 `base-build` 目录存在
- 检查 Node.js 版本兼容性

### **3. 下载失败**
```bash
# 手动下载最新版本
wget https://github.com/wxfyes/ez-theme-builder/releases/latest/download/theme-build.zip
```

## 💡 **优势**

1. **无需本地构建**：利用 GitHub 的强大服务器
2. **自动配置**：根据参数自动生成配置文件
3. **版本管理**：每次构建都有版本号
4. **免费使用**：GitHub Actions 有免费额度

## 🎉 **完成**

设置完成后，你就可以在小服务器上使用强大的云端构建能力了！

## 🎯 **概述**

使用 GitHub Actions 在云端自动构建主题，避免本地服务器资源不足的问题。

## 📋 **设置步骤**

### 1. **推送代码到 GitHub**

```bash
# 确保 .github/workflows/build-theme.yml 文件已创建
git add .
git commit -m "Add GitHub Actions workflow"
git push origin main
```

### 2. **设置 GitHub Token**

1. **生成 Personal Access Token**
   - 进入 GitHub Settings → Developer settings → Personal access tokens
   - 点击 "Generate new token"
   - 选择 "repo" 权限
   - 复制生成的 token

2. **在服务器上设置环境变量**
   ```bash
   # 在服务器上设置
   export GITHUB_TOKEN="your_github_token_here"
   
   # 或者添加到 .env 文件
   echo "GITHUB_TOKEN=your_github_token_here" >> .env
   ```

### 3. **安装依赖**

```bash
# 在服务器上安装 axios
npm install axios
```

## 🚀 **使用方法**

### **方法一：手动触发构建**

1. **进入 GitHub 仓库**
2. **点击 Actions 标签**
3. **选择 "Build EZ Theme" 工作流**
4. **点击 "Run workflow"**
5. **填写构建参数**：
   - Panel Type: 选择面板类型
   - Site Name: 网站名称
   - Site Description: 网站描述
   - API URL: API 地址
6. **点击 "Run workflow"**

### **方法二：通过 API 触发**

```bash
# 发送构建请求
curl -X POST http://your-server:3000/api/build/github-actions \
  -H "Content-Type: application/json" \
  -d '{
    "panel_type": "Xiao-V2board",
    "site_name": "My Theme",
    "site_description": "我的主题",
    "api_url": "https://my-panel.com"
  }'
```

### **方法三：下载最新构建**

```bash
# 获取最新构建信息
curl http://your-server:3000/api/download/latest

# 下载构建文件
wget $(curl -s http://your-server:3000/api/download/latest | jq -r '.download_url')
```

## 📁 **构建结果**

构建完成后，你可以：

1. **从 GitHub Releases 下载**
   - 进入仓库的 Releases 页面
   - 下载 `theme-build.zip` 文件

2. **解压到网站目录**
   ```bash
   unzip theme-build.zip -d /path/to/your/website/
   ```

## 🔧 **故障排除**

### **1. 权限问题**
```bash
# 检查 GitHub Token 是否正确
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user
```

### **2. 工作流失败**
- 检查 GitHub Actions 日志
- 确保 `base-build` 目录存在
- 检查 Node.js 版本兼容性

### **3. 下载失败**
```bash
# 手动下载最新版本
wget https://github.com/wxfyes/ez-theme-builder/releases/latest/download/theme-build.zip
```

## 💡 **优势**

1. **无需本地构建**：利用 GitHub 的强大服务器
2. **自动配置**：根据参数自动生成配置文件
3. **版本管理**：每次构建都有版本号
4. **免费使用**：GitHub Actions 有免费额度

## 🎉 **完成**

设置完成后，你就可以在小服务器上使用强大的云端构建能力了！
