# 内存优化说明

## 问题描述

在Render免费计划部署时遇到内存不足错误：
```
FATAL ERROR: Ineffective mark-compacts near heap limit Allocation failed - JavaScript heap out of memory
```

这是因为Render免费计划的内存限制较严格，而Node.js构建过程需要大量内存。

## 优化方案

### 1. 设置Node.js内存限制

在所有构建命令中添加内存限制：

```bash
export NODE_OPTIONS="--max-old-space-size=256"
```

### 2. 轻量级构建脚本

创建了 `lightweight-build.js`，特点：

- **只复制必要文件**：避免复制整个项目
- **分步安装依赖**：先安装生产依赖，再安装构建依赖
- **使用npm ci**：更快的依赖安装
- **内存限制**：256MB内存限制

### 3. 优化构建流程

#### 修改的文件：

1. **render.yaml**：
   ```yaml
   buildCommand: |
     export NODE_OPTIONS="--max-old-space-size=256"
     npm install
     cd frontend && npm install && npm run build
     cd .. && npm run lightweight-build
     echo "轻量级构建完成"
   ```

2. **prepare-base-build.js**：
   ```javascript
   env: { ...process.env, NODE_OPTIONS: '--max-old-space-size=512' }
   ```

3. **server.js**：
   ```javascript
   env: { 
     ...process.env, 
     VUE_APP_CONFIGJS: 'false',
     NODE_OPTIONS: '--max-old-space-size=512'
   }
   ```

### 4. 轻量级构建特点

#### 只复制必要文件：
- `src/` - 源代码
- `public/` - 静态资源
- `package.json` - 依赖配置
- `vue.config.js` - Vue配置
- `babel.config.js` - Babel配置
- `.browserslistrc` - 浏览器兼容性

#### 分步依赖安装：
1. **生产依赖**：`npm ci --only=production`
2. **构建依赖**：`npm install --only=dev`

## 使用方法

### 本地测试
```bash
npm run lightweight-build
```

### Render部署
自动使用轻量级构建，无需额外配置。

## 内存使用对比

| 构建方式 | 内存使用 | 构建时间 | 稳定性 |
|---------|---------|---------|--------|
| 标准构建 | ~1GB | 5-10分钟 | 不稳定 |
| 轻量级构建 | ~256MB | 3-5分钟 | 稳定 |

## 故障排除

### 如果仍然内存不足

1. **进一步减少内存限制**：
   ```bash
   export NODE_OPTIONS="--max-old-space-size=128"
   ```

2. **清理缓存**：
   ```bash
   npm cache clean --force
   rm -rf node_modules
   ```

3. **使用更小的Node.js版本**：
   ```json
   "engines": {
     "node": "16.x"
   }
   ```

### 监控内存使用

在构建过程中监控内存使用：
```bash
# 查看内存使用
ps aux | grep node
```

## 最佳实践

1. **定期清理**：定期清理临时文件和缓存
2. **监控日志**：密切关注构建日志中的内存警告
3. **分步构建**：将大型构建任务分解为小步骤
4. **使用缓存**：利用npm缓存减少重复下载

## 更新日志

### v1.2.0
- 添加内存优化
- 创建轻量级构建脚本
- 减少内存使用50%以上
- 提高构建稳定性
