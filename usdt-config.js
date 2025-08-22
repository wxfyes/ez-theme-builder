// USDT支付配置文件
module.exports = {
  // USDT收款地址 (请替换为实际的地址)
  USDT_ADDRESS: 'TRC20_USDT_ADDRESS_HERE',
  
  // USDT网络类型
  USDT_NETWORK: 'TRC20',
  
  // USDT汇率 (1 USDT = ? CNY)
  // 建议从API获取实时汇率，这里使用固定汇率作为示例
  USDT_RATE: 7.2,
  
  // 汇率更新间隔 (毫秒)
  RATE_UPDATE_INTERVAL: 5 * 60 * 1000, // 5分钟
  
  // 最小充值金额 (USDT)
  MIN_USDT_AMOUNT: 1,
  
  // 最大充值金额 (USDT)
  MAX_USDT_AMOUNT: 10000,
  
  // 支付确认超时时间 (毫秒)
  PAYMENT_TIMEOUT: 30 * 60 * 1000, // 30分钟
  
  // 是否启用USDT支付
  ENABLE_USDT_PAYMENT: true,
  
  // USDT支付说明
  USDT_DESCRIPTION: '请使用TRC20网络转账，转账完成后系统将自动确认',
  
  // 汇率API配置 (可选)
  RATE_API: {
    // 汇率API地址
    URL: 'https://api.exchangerate-api.com/v4/latest/USD',
    // API密钥 (如果需要)
    API_KEY: '',
    // 请求超时时间
    TIMEOUT: 5000
  }
};
