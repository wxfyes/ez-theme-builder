// Railway保活脚本
const https = require('https');
const http = require('http');

// 配置
const APP_URL = process.env.APP_URL || 'https://ez-theme-builder.onrender.com';
const INTERVAL = 14 * 60 * 1000; // 14分钟发送一次请求

console.log(`🚀 保活脚本启动`);
console.log(`📡 目标URL: ${APP_URL}`);
console.log(`⏰ 间隔时间: ${INTERVAL / 1000 / 60} 分钟`);

function pingApp() {
  const url = new URL(APP_URL);
  const client = url.protocol === 'https:' ? https : http;
  
  const req = client.get(APP_URL + '/api/health', (res) => {
    console.log(`✅ ${new Date().toISOString()} - 保活成功 (${res.statusCode})`);
  });
  
  req.on('error', (err) => {
    console.error(`❌ ${new Date().toISOString()} - 保活失败: ${err.message}`);
  });
  
  req.setTimeout(10000, () => {
    console.error(`⏰ ${new Date().toISOString()} - 保活超时`);
    req.destroy();
  });
}

// 立即执行一次
pingApp();

// 设置定时器
setInterval(pingApp, INTERVAL);

console.log(`✅ 保活脚本已启动，每${INTERVAL / 1000 / 60}分钟发送一次请求`);

// 保持进程运行
process.on('SIGINT', () => {
  console.log('保活脚本已停止');
  process.exit(0);
});
