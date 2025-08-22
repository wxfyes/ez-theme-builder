const { exec } = require('child_process');
const fs = require('fs-extra');
const path = require('path');

async function safeBuild() {
  try {
    console.log('🚀 开始安全构建...');
    
    const baseBuildDir = path.join(__dirname, 'base-build');
    const tempDir = path.join(__dirname, 'temp-safe-build');
    
    // 清理临时目录
    await fs.remove(tempDir);
    await fs.ensureDir(tempDir);
    
    // 检查基础构建是否存在
    const baseBuildExists = await fs.pathExists(baseBuildDir);
    if (!baseBuildExists) {
      console.log('基础构建不存在，正在准备...');
      const { prepareBaseBuild } = require('./prepare-base-build');
      await prepareBaseBuild();
    }
    
    // 安全复制基础构建
    console.log('安全复制基础构建...');
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
        // 排除日志文件
        if (src.includes('.log')) {
          return false;
        }
        return true;
      }
    };
    
    await fs.copy(baseBuildDir, tempDir, copyOptions);
    console.log('基础构建复制完成');
    
    // 安装依赖
    console.log('安装依赖...');
    await new Promise((resolve, reject) => {
      exec('npm install', { cwd: tempDir }, (error, stdout, stderr) => {
        if (error) {
          console.error('依赖安装失败:', error);
          reject(error);
          return;
        }
        console.log('依赖安装完成');
        resolve(stdout);
      });
    });
    
    // 构建项目
    console.log('构建项目...');
    await new Promise((resolve, reject) => {
      exec('npm run build', { 
        cwd: tempDir,
        env: { ...process.env, VUE_APP_CONFIGJS: 'false' }
      }, (error, stdout, stderr) => {
        if (error) {
          console.error('构建失败:', error);
          reject(error);
          return;
        }
        console.log('项目构建完成');
        resolve(stdout);
      });
    });
    
    console.log('✅ 安全构建完成！');
    console.log('构建目录:', tempDir);
    
  } catch (error) {
    console.error('❌ 安全构建失败:', error);
    // 清理临时目录
    try {
      await fs.remove(path.join(__dirname, 'temp-safe-build'));
    } catch (cleanupError) {
      console.error('清理临时目录失败:', cleanupError);
    }
  }
}

// 如果直接运行此脚本
if (require.main === module) {
  safeBuild();
}

module.exports = { safeBuild };
