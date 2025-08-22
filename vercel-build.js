const { exec } = require('child_process');
const fs = require('fs-extra');
const path = require('path');

async function vercelBuild() {
  try {
    console.log('🚀 开始Vercel专用构建...');
    
    const baseBuildDir = path.join(__dirname, 'base-build');
    const tempDir = path.join(__dirname, 'temp-vercel');
    
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
    
    // 只复制必要的文件（Vercel优化）
    console.log('复制必要文件...');
    const essentialFiles = [
      'src',
      'public',
      'package.json',
      'vue.config.js',
      'babel.config.js',
      '.browserslistrc'
    ];
    
    for (const file of essentialFiles) {
      const srcPath = path.join(baseBuildDir, file);
      const destPath = path.join(tempDir, file);
      
      if (await fs.pathExists(srcPath)) {
        await fs.copy(srcPath, destPath);
        console.log(`复制: ${file}`);
      }
    }
    
    // Vercel优化：使用生产模式安装依赖
    console.log('安装生产依赖...');
    await new Promise((resolve, reject) => {
      exec('npm ci --only=production', { 
        cwd: tempDir,
        env: { 
          ...process.env, 
          NODE_OPTIONS: '--max-old-space-size=512',
          NODE_ENV: 'production'
        }
      }, (error, stdout, stderr) => {
        if (error) {
          console.error('生产依赖安装失败:', error);
          reject(error);
          return;
        }
        console.log('生产依赖安装完成');
        resolve(stdout);
      });
    });
    
    // Vercel优化：只安装必要的开发依赖
    console.log('安装构建依赖...');
    const buildDependencies = [
      '@vue/cli-service',
      '@vue/cli-plugin-babel',
      '@vue/cli-plugin-eslint',
      'vue-template-compiler'
    ];
    
    for (const dep of buildDependencies) {
      await new Promise((resolve, reject) => {
        exec(`npm install ${dep} --save-dev`, { 
          cwd: tempDir,
          env: { 
            ...process.env, 
            NODE_OPTIONS: '--max-old-space-size=512',
            NODE_ENV: 'production'
          }
        }, (error, stdout, stderr) => {
          if (error) {
            console.error(`安装 ${dep} 失败:`, error);
            reject(error);
            return;
          }
          console.log(`${dep} 安装完成`);
          resolve(stdout);
        });
      });
    }
    
    // Vercel优化：使用512MB内存限制构建
    console.log('开始Vercel优化构建...');
    await new Promise((resolve, reject) => {
      exec('npm run build', { 
        cwd: tempDir,
        env: { 
          ...process.env, 
          VUE_APP_CONFIGJS: 'false',
          NODE_OPTIONS: '--max-old-space-size=512',
          NODE_ENV: 'production'
        }
      }, (error, stdout, stderr) => {
        if (error) {
          console.error('构建失败:', error);
          reject(error);
          return;
        }
        console.log('Vercel优化构建完成');
        resolve(stdout);
      });
    });
    
    console.log('✅ Vercel专用构建完成！');
    console.log('构建目录:', tempDir);
    console.log('内存使用: 512MB (Vercel免费计划优化)');
    
  } catch (error) {
    console.error('❌ Vercel构建失败:', error);
    // 清理临时目录
    try {
      await fs.remove(path.join(__dirname, 'temp-vercel'));
    } catch (cleanupError) {
      console.error('清理临时目录失败:', cleanupError);
    }
  }
}

// 如果直接运行此脚本
if (require.main === module) {
  vercelBuild();
}

module.exports = { vercelBuild };
