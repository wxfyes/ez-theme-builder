# 构建问题修复说明

## 问题描述

在Render部署过程中遇到以下错误：
```
Error: Cannot copy '../json5/lib/cli.js' to a subdirectory of itself, './json5/lib/cli.js'.
```

这是因为在复制预构建项目时，源目录和目标目录存在重叠，导致文件复制冲突。

## 修复方案

### 1. 使用临时目录构建

修改了 `prepare-base-build.js`，使用临时目录进行构建：

```javascript
// 使用临时目录避免冲突
const tempDir = path.join(__dirname, 'temp-base-build');
await fs.remove(tempDir);
await fs.ensureDir(tempDir);

// 在临时目录中构建
await exec('npm install', { cwd: tempDir });
await exec('npm run build', { cwd: tempDir });

// 复制到最终目录
await fs.copy(tempDir, baseBuildDir);
await fs.remove(tempDir);
```

### 2. 安全复制过滤器

在 `server.js` 中添加了复制过滤器，排除可能导致冲突的文件：

```javascript
const copyOptions = {
  filter: (src, dest) => {
    // 排除node_modules目录
    if (src.includes('node_modules')) {
      return false;
    }
    // 排除.git目录
    if (src.includes('.git')) {
      return false;
    }
    // 排除临时文件
    if (src.includes('.tmp') || src.includes('.temp')) {
      return false;
    }
    return true;
  }
};

await fs.copy(baseBuildDir, buildDir, copyOptions);
```

### 3. 重新安装依赖

在构建过程中重新安装依赖，确保依赖关系正确：

```javascript
// 先安装依赖
await exec('npm install', { cwd: buildDir });

// 然后构建项目
await exec('npm run build', { cwd: buildDir });
```

## 新增文件

### safe-build.js
创建了一个更安全的构建脚本，包含完整的错误处理和清理逻辑。

### 使用方法
```bash
npm run safe-build
```

## 部署建议

### Render部署
1. 使用修改后的构建命令
2. 确保环境变量正确设置
3. 监控构建日志

### 本地测试
1. 运行 `npm run safe-build` 测试构建
2. 检查生成的临时目录
3. 验证构建结果

## 故障排除

### 如果仍然遇到问题

1. **清理缓存**：
   ```bash
   rm -rf node_modules
   rm -rf base-build
   npm install
   npm run prepare-base
   ```

2. **检查磁盘空间**：
   确保有足够的磁盘空间进行构建

3. **检查权限**：
   确保有足够的文件系统权限

4. **使用安全构建**：
   ```bash
   npm run safe-build
   ```

## 监控和日志

构建过程现在包含详细的日志输出：
- 每个步骤的状态
- 错误详情
- 清理操作确认

## 更新日志

### v1.1.0
- 修复文件复制冲突问题
- 添加安全构建脚本
- 改进错误处理
- 增加详细日志输出
