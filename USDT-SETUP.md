# USDT支付配置指南

## 概述

EZ-Theme Builder现在支持USDT支付，用户可以使用USDT (TRC20) 进行充值。

## 配置步骤

### 1. 配置USDT收款地址

编辑 `usdt-config.js` 文件：

```javascript
// 将以下地址替换为你的实际USDT收款地址
USDT_ADDRESS: 'TRC20_USDT_ADDRESS_HERE',
```

**重要**: 请确保使用TRC20网络的USDT地址。

### 2. 配置汇率

在 `usdt-config.js` 中设置USDT汇率：

```javascript
// 1 USDT = ? CNY (人民币)
USDT_RATE: 7.2,
```

**建议**: 使用实时汇率API获取最新汇率。

### 3. 配置金额限制

```javascript
// 最小充值金额 (USDT)
MIN_USDT_AMOUNT: 1,

// 最大充值金额 (USDT)
MAX_USDT_AMOUNT: 10000,
```

### 4. 启用/禁用USDT支付

```javascript
// 是否启用USDT支付
ENABLE_USDT_PAYMENT: true,
```

## 功能特性

### ✅ 已实现功能

1. **USDT支付选项** - 在支付方式中添加USDT选项
2. **汇率显示** - 实时显示USDT汇率
3. **地址复制** - 一键复制USDT收款地址
4. **金额验证** - 自动验证充值金额范围
5. **支付状态检查** - 支持检查USDT支付状态

### 🔄 支付流程

1. 用户选择USDT支付方式
2. 系统计算USDT金额 (CNY金额 ÷ 汇率)
3. 显示USDT收款地址和金额
4. 用户使用TRC20网络转账
5. 系统检查支付状态
6. 支付成功后自动充值积分

## API接口

### 获取USDT汇率
```
GET /api/usdt/rate
```

响应示例：
```json
{
  "rate": 7.2,
  "network": "TRC20",
  "enabled": true,
  "min_amount": 1,
  "max_amount": 10000
}
```

### 创建USDT订单
```
POST /api/orders/create
```

请求体：
```json
{
  "amount": 100,
  "payment_method": "usdt"
}
```

响应示例：
```json
{
  "order_id": "ORDER_1234567890_abc123",
  "amount": 100,
  "payment_method": "usdt",
  "usdt_amount": "13.89",
  "usdt_address": "TRC20_USDT_ADDRESS_HERE",
  "status": "pending"
}
```

## 安全注意事项

1. **地址安全** - 确保USDT收款地址的安全性
2. **汇率更新** - 定期更新USDT汇率
3. **金额验证** - 验证转账金额是否匹配订单
4. **网络确认** - 确保使用TRC20网络

## 故障排除

### 常见问题

1. **USDT支付选项不显示**
   - 检查 `ENABLE_USDT_PAYMENT` 是否为 `true`
   - 检查前端代码是否正确加载

2. **汇率显示错误**
   - 检查 `USDT_RATE` 配置
   - 检查 `/api/usdt/rate` 接口是否正常

3. **地址复制失败**
   - 检查浏览器是否支持剪贴板API
   - 检查USDT地址是否正确配置

4. **支付状态检查失败**
   - 检查订单ID是否正确
   - 检查数据库连接是否正常

## 扩展功能

### 实时汇率API

可以集成实时汇率API来自动更新USDT汇率：

```javascript
// 在 usdt-config.js 中配置
RATE_API: {
  URL: 'https://api.exchangerate-api.com/v4/latest/USD',
  API_KEY: 'your-api-key',
  TIMEOUT: 5000
}
```

### 自动支付检测

可以集成区块链API来自动检测USDT转账：

```javascript
// 示例：使用TronScan API检测转账
const checkUsdtPayment = async (address, amount, orderId) => {
  // 实现自动检测逻辑
}
```

## 更新日志

### v1.0.0
- 初始USDT支付功能
- 支持TRC20网络
- 基础汇率配置
- 地址复制功能
- 支付状态检查
