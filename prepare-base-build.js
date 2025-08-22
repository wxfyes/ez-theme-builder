const { exec } = require('child_process');
const fs = require('fs-extra');
const path = require('path');

async function prepareBaseBuild() {
  try {
    console.log('开始准备基础构建...');
    
    const baseBuildDir = path.join(__dirname, 'base-build');
    const tempDir = path.join(__dirname, 'temp-base-build');
    
    // 清理目录
    await fs.remove(baseBuildDir);
    await fs.remove(tempDir);
    await fs.ensureDir(tempDir);
    
    // 克隆EZ-Theme项目到临时目录
    console.log('克隆EZ-Theme项目...');
    await new Promise((resolve, reject) => {
      exec(`git clone https://github.com/wxfyes/EZ-Theme.git ${tempDir}`, (error, stdout, stderr) => {
        if (error) {
          console.error('Git克隆错误:', error);
          reject(error);
          return;
        }
        console.log('Git克隆完成');
        resolve(stdout);
      });
    });
    
    // 安装依赖
    console.log('安装依赖...');
    await new Promise((resolve, reject) => {
      exec('npm install', { 
        cwd: tempDir,
        env: { ...process.env, NODE_OPTIONS: '--max-old-space-size=512' }
      }, (error, stdout, stderr) => {
        if (error) {
          console.error('依赖安装错误:', error);
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
        env: { ...process.env, NODE_OPTIONS: '--max-old-space-size=512' }
      }, (error, stdout, stderr) => {
        if (error) {
          console.error('构建错误:', error);
          reject(error);
          return;
        }
        console.log('项目构建完成');
        resolve(stdout);
      });
    });
    
    // 复制到最终目录
    console.log('复制到最终目录...');
    await fs.copy(tempDir, baseBuildDir);
    
    // 清理临时目录
    await fs.remove(tempDir);
    
    console.log('基础构建准备完成！');
    console.log('基础构建目录:', baseBuildDir);
    
  } catch (error) {
    console.error('基础构建准备失败:', error);
    // 清理临时目录
    try {
      await fs.remove(path.join(__dirname, 'temp-base-build'));
    } catch (cleanupError) {
      console.error('清理临时目录失败:', cleanupError);
    }
  }
}

// 如果直接运行此脚本
if (require.main === module) {
  prepareBaseBuild();
}

module.exports = { prepareBaseBuild };
