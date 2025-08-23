const express = require('express');
const axios = require('axios');
const fs = require('fs-extra');
const path = require('path');
const archiver = require('archiver');

const app = express();
app.use(express.json());

// GitHub Actions 构建处理
app.post('/api/build/github-actions', async (req, res) => {
  try {
    const { panel_type, site_name, site_description, api_url } = req.body;
    
    console.log('收到 GitHub Actions 构建请求:', {
      panel_type,
      site_name,
      site_description,
      api_url
    });

    // 生成构建ID
    const buildId = `BUILD_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // 创建构建目录
    const buildDir = path.join(__dirname, 'temp', buildId);
    await fs.ensureDir(buildDir);

    // 触发 GitHub Actions
    const githubToken = process.env.GITHUB_TOKEN;
    const repoOwner = 'wxfyes';
    const repoName = 'ez-theme-builder';
    
    const workflowResponse = await axios.post(
      `https://api.github.com/repos/${repoOwner}/${repoName}/actions/workflows/build-theme.yml/dispatches`,
      {
        ref: 'main',
        inputs: {
          panel_type: panel_type || 'Xiao-V2board',
          site_name: site_name || 'EZ Theme',
          site_description: site_description || '专业的主题生成服务',
          api_url: api_url || 'https://your-panel.com'
        }
      },
      {
        headers: {
          'Authorization': `token ${githubToken}`,
          'Accept': 'application/vnd.github.v3+json'
        }
      }
    );

    console.log('GitHub Actions 已触发');

    // 返回构建信息
    res.json({
      success: true,
      build_id: buildId,
      message: 'GitHub Actions 构建已触发，请稍后查看构建结果',
      github_workflow_url: `https://github.com/${repoOwner}/${repoName}/actions`
    });

  } catch (error) {
    console.error('GitHub Actions 构建失败:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// 检查构建状态
app.get('/api/build/:buildId/status', async (req, res) => {
  try {
    const { buildId } = req.params;
    
    // 这里可以检查 GitHub Actions 的构建状态
    // 暂时返回模拟状态
    res.json({
      build_id: buildId,
      status: 'building',
      message: '构建中，请稍后...'
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// 下载构建结果
app.get('/api/build/:buildId/download', async (req, res) => {
  try {
    const { buildId } = req.params;
    
    // 检查构建文件是否存在
    const buildFile = path.join(__dirname, 'builds', `${buildId}.zip`);
    
    if (await fs.pathExists(buildFile)) {
      res.download(buildFile);
    } else {
      res.status(404).json({
        success: false,
        error: '构建文件不存在'
      });
    }

  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// 从 GitHub Releases 下载最新构建
app.get('/api/download/latest', async (req, res) => {
  try {
    const { panel_type = 'Xiao-V2board' } = req.query;
    
    // 获取最新的 release
    const releasesResponse = await axios.get(
      'https://api.github.com/repos/wxfyes/ez-theme-builder/releases/latest'
    );
    
    const latestRelease = releasesResponse.data;
    const asset = latestRelease.assets.find(a => a.name === 'theme-build.zip');
    
    if (asset) {
      res.json({
        success: true,
        download_url: asset.browser_download_url,
        release_name: latestRelease.name,
        release_tag: latestRelease.tag_name
      });
    } else {
      res.status(404).json({
        success: false,
        error: '未找到构建文件'
      });
    }

  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = app;
const axios = require('axios');
const fs = require('fs-extra');
const path = require('path');
const archiver = require('archiver');

const app = express();
app.use(express.json());

// GitHub Actions 构建处理
app.post('/api/build/github-actions', async (req, res) => {
  try {
    const { panel_type, site_name, site_description, api_url } = req.body;
    
    console.log('收到 GitHub Actions 构建请求:', {
      panel_type,
      site_name,
      site_description,
      api_url
    });

    // 生成构建ID
    const buildId = `BUILD_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // 创建构建目录
    const buildDir = path.join(__dirname, 'temp', buildId);
    await fs.ensureDir(buildDir);

    // 触发 GitHub Actions
    const githubToken = process.env.GITHUB_TOKEN;
    const repoOwner = 'wxfyes';
    const repoName = 'ez-theme-builder';
    
    const workflowResponse = await axios.post(
      `https://api.github.com/repos/${repoOwner}/${repoName}/actions/workflows/build-theme.yml/dispatches`,
      {
        ref: 'main',
        inputs: {
          panel_type: panel_type || 'Xiao-V2board',
          site_name: site_name || 'EZ Theme',
          site_description: site_description || '专业的主题生成服务',
          api_url: api_url || 'https://your-panel.com'
        }
      },
      {
        headers: {
          'Authorization': `token ${githubToken}`,
          'Accept': 'application/vnd.github.v3+json'
        }
      }
    );

    console.log('GitHub Actions 已触发');

    // 返回构建信息
    res.json({
      success: true,
      build_id: buildId,
      message: 'GitHub Actions 构建已触发，请稍后查看构建结果',
      github_workflow_url: `https://github.com/${repoOwner}/${repoName}/actions`
    });

  } catch (error) {
    console.error('GitHub Actions 构建失败:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// 检查构建状态
app.get('/api/build/:buildId/status', async (req, res) => {
  try {
    const { buildId } = req.params;
    
    // 这里可以检查 GitHub Actions 的构建状态
    // 暂时返回模拟状态
    res.json({
      build_id: buildId,
      status: 'building',
      message: '构建中，请稍后...'
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// 下载构建结果
app.get('/api/build/:buildId/download', async (req, res) => {
  try {
    const { buildId } = req.params;
    
    // 检查构建文件是否存在
    const buildFile = path.join(__dirname, 'builds', `${buildId}.zip`);
    
    if (await fs.pathExists(buildFile)) {
      res.download(buildFile);
    } else {
      res.status(404).json({
        success: false,
        error: '构建文件不存在'
      });
    }

  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// 从 GitHub Releases 下载最新构建
app.get('/api/download/latest', async (req, res) => {
  try {
    const { panel_type = 'Xiao-V2board' } = req.query;
    
    // 获取最新的 release
    const releasesResponse = await axios.get(
      'https://api.github.com/repos/wxfyes/ez-theme-builder/releases/latest'
    );
    
    const latestRelease = releasesResponse.data;
    const asset = latestRelease.assets.find(a => a.name === 'theme-build.zip');
    
    if (asset) {
      res.json({
        success: true,
        download_url: asset.browser_download_url,
        release_name: latestRelease.name,
        release_tag: latestRelease.tag_name
      });
    } else {
      res.status(404).json({
        success: false,
        error: '未找到构建文件'
      });
    }

  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = app;
