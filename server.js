const { exec } = require('child_process');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const archiver = require('archiver');
const fs = require('fs-extra');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const rateLimit = require('express-rate-limit');
const { body, validationResult } = require('express-validator');
const sqlite3 = require('sqlite3').verbose();
const moment = require('moment');
const QRCode = require('qrcode');
const crypto = require('crypto');
const usdtConfig = require('./usdt-config');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件 - 完全禁用CSP
app.use(helmet({
  crossOriginEmbedderPolicy: false,
  crossOriginOpenerPolicy: false,
  crossOriginResourcePolicy: false,
  originAgentCluster: false,
  contentSecurityPolicy: false
}));
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// 配置multer用于文件上传
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024 // 限制5MB
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('只允许上传图片文件'));
    }
  }
});

// 速率限制
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15分钟
  max: 100 // 限制每个IP 15分钟内最多100个请求
});
app.use(limiter);

// 数据库初始化
const db = new sqlite3.Database('./database.sqlite');
db.serialize(() => {
  // 用户表
  db.run(`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    api_key TEXT UNIQUE,
    credits INTEGER DEFAULT 0,
    is_admin BOOLEAN DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  // 订单表
  db.run(`CREATE TABLE IF NOT EXISTS orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    order_id TEXT UNIQUE NOT NULL,
    amount REAL NOT NULL,
    status TEXT DEFAULT 'pending',
    payment_method TEXT,
    payment_url TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id)
  )`);

  // 构建记录表
  db.run(`CREATE TABLE IF NOT EXISTS builds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    build_id TEXT UNIQUE NOT NULL,
    config_data TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    download_url TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id)
  )`);

  // 系统配置表
  db.run(`CREATE TABLE IF NOT EXISTS system_config (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key TEXT UNIQUE NOT NULL,
    value TEXT NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  // 插入默认管理员账户
  const adminPassword = bcrypt.hashSync('admin123', 10);
  db.run(`INSERT OR IGNORE INTO users (username, email, password, is_admin, credits) 
          VALUES ('admin', 'admin@example.com', ?, 1, 999999)`, [adminPassword]);

  // 插入默认系统配置
  db.run(`INSERT OR IGNORE INTO system_config (key, value) VALUES 
          ('license_key', 'demo-key-123'),
          ('price_per_build', '10'),
          ('max_builds_per_day', '5'),
          ('payment_methods', 'alipay,wechat,paypal')`);
});

// JWT中间件
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: '访问令牌缺失' });
  }

  jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key', (err, user) => {
    if (err) {
      return res.status(403).json({ error: '访问令牌无效' });
    }
    req.user = user;
    next();
  });
};

// API密钥验证中间件
const authenticateApiKey = (req, res, next) => {
  const apiKey = req.headers['x-api-key'] || req.query.api_key;
  
  if (!apiKey) {
    return res.status(401).json({ error: 'API密钥缺失' });
  }

  db.get('SELECT * FROM users WHERE api_key = ?', [apiKey], (err, user) => {
    if (err || !user) {
      return res.status(403).json({ error: 'API密钥无效' });
    }
    req.user = user;
    next();
  });
};

// 用户注册
app.post('/api/auth/register', [
  body('username').isLength({ min: 3 }).withMessage('用户名至少3个字符'),
  body('email').isEmail().withMessage('邮箱格式无效'),
  body('password').isLength({ min: 6 }).withMessage('密码至少6个字符')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { username, email, password } = req.body;
  const hashedPassword = bcrypt.hashSync(password, 10);
  const apiKey = crypto.randomBytes(32).toString('hex');

  db.run('INSERT INTO users (username, email, password, api_key) VALUES (?, ?, ?, ?)',
    [username, email, hashedPassword, apiKey],
    function(err) {
      if (err) {
        if (err.message.includes('UNIQUE constraint failed')) {
          return res.status(400).json({ error: '用户名或邮箱已存在' });
        }
        return res.status(500).json({ error: '注册失败' });
      }

      const token = jwt.sign({ id: this.lastID, username }, process.env.JWT_SECRET || 'your-secret-key', { expiresIn: '24h' });
      res.json({ 
        message: '注册成功', 
        token, 
        user: { id: this.lastID, username, email, api_key: apiKey }
      });
    });
});

// 用户登录
app.post('/api/auth/login', [
  body('username').notEmpty().withMessage('用户名不能为空'),
  body('password').notEmpty().withMessage('密码不能为空')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { username, password } = req.body;

  db.get('SELECT * FROM users WHERE username = ? OR email = ?', [username, username], (err, user) => {
    if (err || !user) {
      return res.status(401).json({ error: '用户名或密码错误' });
    }

    if (!bcrypt.compareSync(password, user.password)) {
      return res.status(401).json({ error: '用户名或密码错误' });
    }

    const token = jwt.sign({ id: user.id, username: user.username }, process.env.JWT_SECRET || 'your-secret-key', { expiresIn: '24h' });
    res.json({ 
      message: '登录成功', 
      token, 
      user: { 
        id: user.id, 
        username: user.username, 
        email: user.email, 
        api_key: user.api_key,
        credits: user.credits,
        is_admin: user.is_admin 
      }
    });
  });
});

// 获取用户信息
app.get('/api/user/profile', authenticateToken, (req, res) => {
  db.get('SELECT id, username, email, api_key, credits, is_admin, created_at FROM users WHERE id = ?', 
    [req.user.id], (err, user) => {
    if (err || !user) {
      return res.status(404).json({ error: '用户不存在' });
    }
    res.json({ user });
  });
});

// 创建订单
app.post('/api/orders/create', authenticateToken, [
  body('amount').isFloat({ min: 1 }).withMessage('金额必须大于0')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { amount, payment_method = 'alipay' } = req.body;
  const orderId = `ORDER_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

  // USDT支付处理
  if (payment_method === 'usdt') {
    // 检查USDT支付是否启用
    if (!usdtConfig.ENABLE_USDT_PAYMENT) {
      return res.status(400).json({ error: 'USDT支付功能已禁用' });
    }
    
    // 检查金额限制
    const usdtAmount = (amount / usdtConfig.USDT_RATE).toFixed(2);
    if (usdtAmount < usdtConfig.MIN_USDT_AMOUNT) {
      return res.status(400).json({ error: `最小充值金额为 ${usdtConfig.MIN_USDT_AMOUNT} USDT` });
    }
    if (usdtAmount > usdtConfig.MAX_USDT_AMOUNT) {
      return res.status(400).json({ error: `最大充值金额为 ${usdtConfig.MAX_USDT_AMOUNT} USDT` });
    }
    
    // USDT收款地址
    const usdtAddress = usdtConfig.USDT_ADDRESS;
    
    db.run('INSERT INTO orders (user_id, order_id, amount, payment_method, payment_url) VALUES (?, ?, ?, ?, ?)',
      [req.user.id, orderId, amount, payment_method, usdtAddress],
      function(err) {
        if (err) {
          return res.status(500).json({ error: '创建订单失败' });
        }

        res.json({
          order_id: orderId,
          amount,
          payment_method: 'usdt',
          usdt_amount: usdtAmount,
          usdt_address: usdtAddress,
          status: 'pending'
        });
      });
    return;
  }

  // 其他支付方式处理
  const paymentUrl = `https://example.com/pay/${orderId}`;
  let qrCodeDataUrl;
  try {
    qrCodeDataUrl = await QRCode.toDataURL(paymentUrl);
  } catch (err) {
    qrCodeDataUrl = null;
  }

  db.run('INSERT INTO orders (user_id, order_id, amount, payment_method, payment_url) VALUES (?, ?, ?, ?, ?)',
    [req.user.id, orderId, amount, payment_method, paymentUrl],
    function(err) {
      if (err) {
        return res.status(500).json({ error: '创建订单失败' });
      }

      res.json({
        order_id: orderId,
        amount,
        payment_url: paymentUrl,
        qr_code: qrCodeDataUrl,
        status: 'pending'
      });
    });
});

// 获取USDT汇率
app.get('/api/usdt/rate', (req, res) => {
  res.json({
    rate: usdtConfig.USDT_RATE,
    network: usdtConfig.USDT_NETWORK,
    enabled: usdtConfig.ENABLE_USDT_PAYMENT,
    min_amount: usdtConfig.MIN_USDT_AMOUNT,
    max_amount: usdtConfig.MAX_USDT_AMOUNT
  });
});

// 检查订单状态
app.get('/api/orders/:orderId/status', authenticateToken, (req, res) => {
  const { orderId } = req.params;

  db.get('SELECT * FROM orders WHERE order_id = ? AND user_id = ?', [orderId, req.user.id], (err, order) => {
    if (err || !order) {
      return res.status(404).json({ error: '订单不存在' });
    }

    // USDT支付特殊处理
    if (order.payment_method === 'usdt') {
      const usdtAmount = (order.amount / usdtConfig.USDT_RATE).toFixed(2);
      const usdtAddress = order.payment_url; // 存储的是USDT地址

      res.json({
        order_id: order.order_id,
        amount: order.amount,
        payment_method: order.payment_method,
        usdt_amount: usdtAmount,
        usdt_address: usdtAddress,
        status: order.status,
        created_at: order.created_at
      });
    } else {
      res.json({
        order_id: order.order_id,
        amount: order.amount,
        payment_method: order.payment_method,
        status: order.status,
        created_at: order.created_at
      });
    }
  });
});

// 模拟支付成功（实际项目中应该由支付回调处理）
app.post('/api/orders/:orderId/pay', authenticateToken, (req, res) => {
  const { orderId } = req.params;

  db.run('UPDATE orders SET status = ? WHERE order_id = ? AND user_id = ?', 
    ['paid', orderId, req.user.id], function(err) {
    if (err || this.changes === 0) {
      return res.status(404).json({ error: '订单不存在或更新失败' });
    }

    // 更新用户余额
    db.run('UPDATE users SET credits = credits + (SELECT amount FROM orders WHERE order_id = ?) WHERE id = ?',
      [orderId, req.user.id], (err) => {
      if (err) {
        return res.status(500).json({ error: '更新余额失败' });
      }

      res.json({ message: '支付成功', status: 'paid' });
    });
  });
});

// 创建主题构建
app.post('/api/builds/create', authenticateToken, upload.single('logo'), async (req, res) => {
  try {
    // 解析配置数据
    let configData;
    try {
      configData = JSON.parse(req.body.config_data);
    } catch (error) {
      return res.status(400).json({ error: '配置数据格式错误' });
    }

    // 检查用户余额
    db.get('SELECT credits FROM users WHERE id = ?', [req.user.id], (err, user) => {
      if (err || !user) {
        return res.status(404).json({ error: '用户不存在' });
      }

      db.get('SELECT value FROM system_config WHERE key = ?', ['price_per_build'], (err, config) => {
        const pricePerBuild = parseInt(config?.value || 10);
        
        if (user.credits < pricePerBuild) {
          return res.status(402).json({ error: '余额不足，请先充值' });
        }

        const buildId = `BUILD_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

        // 扣除余额
        db.run('UPDATE users SET credits = credits - ? WHERE id = ?', [pricePerBuild, req.user.id], (err) => {
          if (err) {
            return res.status(500).json({ error: '扣除余额失败' });
          }

          // 创建构建记录
          db.run('INSERT INTO builds (user_id, build_id, config_data) VALUES (?, ?, ?)',
            [req.user.id, buildId, JSON.stringify(configData)],
            function(err) {
            if (err) {
              return res.status(500).json({ error: '创建构建失败' });
            }

            // 异步处理构建，传递logo文件
            processBuild(buildId, configData, req.file);

            res.json({
              build_id: buildId,
              status: 'pending',
              message: '构建已开始，请稍后查看结果'
            });
          });
        });
      });
    });
  } catch (error) {
    console.error('构建创建错误:', error);
    res.status(500).json({ error: '构建创建失败' });
  }
});

// 使用API密钥创建构建
app.post('/api/builds/create-with-key', authenticateApiKey, [
  body('config_data').isObject().withMessage('配置数据格式错误')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { config_data } = req.body;
  const buildId = `BUILD_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

  // 创建构建记录
  db.run('INSERT INTO builds (user_id, build_id, config_data) VALUES (?, ?, ?)',
    [req.user.id, buildId, JSON.stringify(config_data)],
    function(err) {
    if (err) {
      return res.status(500).json({ error: '创建构建失败' });
    }

    // 异步处理构建
    processBuild(buildId, config_data);

    res.json({
      build_id: buildId,
      status: 'pending',
      message: '构建已开始，请稍后查看结果'
    });
  });
});

// 获取构建状态
app.get('/api/builds/:buildId', authenticateToken, (req, res) => {
  const { buildId } = req.params;

  db.get('SELECT * FROM builds WHERE build_id = ? AND user_id = ?', [buildId, req.user.id], (err, build) => {
    if (err || !build) {
      return res.status(404).json({ error: '构建不存在' });
    }

    res.json({
      build_id: build.build_id,
      status: build.status,
      download_url: build.download_url,
      created_at: build.created_at
    });
  });
});

// 获取用户构建列表
app.get('/api/builds', authenticateToken, (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const offset = (page - 1) * limit;

  db.all('SELECT build_id, status, download_url, created_at FROM builds WHERE user_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?',
    [req.user.id, limit, offset], (err, builds) => {
    if (err) {
      return res.status(500).json({ error: '获取构建列表失败' });
    }

    db.get('SELECT COUNT(*) as total FROM builds WHERE user_id = ?', [req.user.id], (err, count) => {
      res.json({
        builds,
        pagination: {
          page,
          limit,
          total: count.total,
          pages: Math.ceil(count.total / limit)
        }
      });
    });
  });
});

// 重试构建
app.post('/api/builds/:buildId/retry', authenticateToken, async (req, res) => {
  const { buildId } = req.params;
  console.log(`收到重试构建请求: ${buildId}, 用户ID: ${req.user.id}`);

  // 检查构建是否存在且属于当前用户
  db.get('SELECT * FROM builds WHERE build_id = ? AND user_id = ?', [buildId, req.user.id], async (err, build) => {
    if (err || !build) {
      return res.status(404).json({ error: '构建不存在' });
    }

    if (build.status === 'processing') {
      return res.status(400).json({ error: '构建正在进行中' });
    }

    // 检查用户余额
    db.get('SELECT credits FROM users WHERE id = ?', [req.user.id], (err, user) => {
      if (err || !user) {
        return res.status(404).json({ error: '用户不存在' });
      }

      db.get('SELECT value FROM system_config WHERE key = ?', ['price_per_build'], (err, config) => {
        const pricePerBuild = parseInt(config?.value || 10);
        
        if (user.credits < pricePerBuild) {
          return res.status(402).json({ error: '余额不足，请先充值' });
        }

        // 扣除余额
        db.run('UPDATE users SET credits = credits - ? WHERE id = ?', [pricePerBuild, req.user.id], (err) => {
          if (err) {
            return res.status(500).json({ error: '扣除余额失败' });
          }

          // 重置构建状态
          db.run('UPDATE builds SET status = ? WHERE build_id = ?', ['pending', buildId], (err) => {
            if (err) {
              return res.status(500).json({ error: '重置构建状态失败' });
            }

            // 重新开始构建
            console.log('准备重新开始构建，配置数据长度:', build.config_data.length);
            const configData = JSON.parse(build.config_data);
            console.log('解析配置数据成功，开始调用processBuild');
            processBuild(buildId, configData);

            res.json({ 
              message: '重试构建已开始',
              build_id: buildId,
              status: 'pending'
            });
          });
        });
      });
    });
  });
});

// 下载构建文件
app.get('/api/builds/:buildId/download', authenticateToken, (req, res) => {
  const { buildId } = req.params;

  db.get('SELECT * FROM builds WHERE build_id = ? AND user_id = ?', [buildId, req.user.id], (err, build) => {
    if (err || !build) {
      return res.status(404).json({ error: '构建不存在' });
    }

    if (build.status !== 'completed') {
      return res.status(400).json({ error: '构建尚未完成' });
    }

    const filePath = path.join(__dirname, 'builds', `${buildId}.zip`);
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ error: '文件不存在' });
    }

    res.download(filePath, `ez-theme-${buildId}.zip`);
  });
});

// 获取系统配置
app.get('/api/system/config', (req, res) => {
  db.all('SELECT key, value FROM system_config', (err, configs) => {
    if (err) {
      return res.status(500).json({ error: '获取配置失败' });
    }

    const config = {};
    configs.forEach(item => {
      config[item.key] = item.value;
    });

    res.json({ config });
  });
});

// 管理员更新系统配置
app.post('/api/admin/config', authenticateToken, (req, res) => {
  // 检查是否为管理员
  db.get('SELECT is_admin FROM users WHERE id = ?', [req.user.id], (err, user) => {
    if (err || !user || !user.is_admin) {
      return res.status(403).json({ error: '权限不足' });
    }

    const { key, value } = req.body;
    db.run('INSERT OR REPLACE INTO system_config (key, value, updated_at) VALUES (?, ?, CURRENT_TIMESTAMP)',
      [key, value], function(err) {
      if (err) {
        return res.status(500).json({ error: '更新配置失败' });
      }

      res.json({ message: '配置更新成功' });
    });
  });
});

// 异步处理构建
async function processBuild(buildId, configData, logoFile = null) {
  try {
    console.log('==========================================');
    console.log(`🚀 开始处理构建: ${buildId}`);
    console.log('==========================================');
    
    // 更新构建状态为处理中
    db.run('UPDATE builds SET status = ? WHERE build_id = ?', ['processing', buildId]);
    console.log('构建状态已更新为处理中');

    // 创建构建目录
    const buildDir = path.join(__dirname, 'temp', buildId);
    const outputDir = path.join(__dirname, 'builds');
    const baseBuildDir = path.join(__dirname, 'base-build');
    
    await fs.ensureDir(buildDir);
    await fs.ensureDir(outputDir);
    console.log('构建目录已创建');

    // 检查基础构建是否存在
    const baseBuildExists = await fs.pathExists(baseBuildDir);
    if (!baseBuildExists) {
      console.log('基础构建不存在，正在准备...');
      const { prepareBaseBuild } = require('./prepare-base-build');
      await prepareBaseBuild();
    }

    // 复制预构建的基础项目
    console.log('复制预构建的基础项目...');
    await fs.copy(baseBuildDir, buildDir);
    console.log('基础项目复制完成');

    console.log('=== 开始生成配置文件 ===');
    try {
      // 读取配置文件模板
      const templatePath = path.join(__dirname, 'config-template.js');
      let templateContent = await fs.readFile(templatePath, 'utf8');
      console.log('配置文件模板读取成功');
      
      // 替换模板中的占位符
      const replaceTemplateValue = (obj, path = '') => {
        for (const key in obj) {
          const currentPath = path ? `${path}.${key}` : key;
          const value = obj[key];
          
          if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
            replaceTemplateValue(value, currentPath);
          } else {
            const placeholder = `{{${currentPath}}}`;
            let replacement;
            if (typeof value === 'string') {
              // 对于字符串值，总是添加引号
              replacement = `'${value}'`;
            } else {
              replacement = JSON.stringify(value);
            }
            
            // 先尝试替换带引号的占位符
            const placeholderWithQuotes = `'${placeholder}'`;
            let newContent = templateContent.replace(new RegExp(placeholderWithQuotes.replace(/\./g, '\\.'), 'g'), replacement);
            
            // 如果没有找到带引号的，再尝试替换不带引号的
            if (newContent === templateContent) {
              newContent = templateContent.replace(new RegExp(placeholder.replace(/\./g, '\\.'), 'g'), replacement);
            }
            if (newContent !== templateContent) {
              console.log(`替换占位符: ${placeholder} -> ${replacement}`);
              templateContent = newContent;
            } else {
              console.log(`未找到占位符: ${placeholder}`);
            }
          }
        }
      };
      
      console.log('开始替换模板占位符...');
      replaceTemplateValue(configData);
      console.log('模板占位符替换完成');
      
      // 删除原始配置文件并写入新的配置文件
      const configPath = path.join(buildDir, 'src', 'config', 'index.js');
      console.log('配置文件路径:', configPath);
      
      // 先检查原始文件是否存在
      const originalExists = await fs.pathExists(configPath);
      if (originalExists) {
        console.log('原始配置文件存在，准备删除...');
        const originalContent = await fs.readFile(configPath, 'utf8');
        console.log('原始文件内容长度:', originalContent.length);
        console.log('原始文件前100字符:', originalContent.substring(0, 100));
        
        // 删除原始文件
        await fs.remove(configPath);
        console.log('原始配置文件已删除');
      }
      
      // 写入新的配置文件
      console.log('写入新配置文件，内容长度:', templateContent.length);
      await fs.writeFile(configPath, templateContent);
      console.log('新配置文件写入完成');
      
      // 验证文件是否被正确写入
      const writtenContent = await fs.readFile(configPath, 'utf8');
      console.log('验证: 写入的文件内容长度:', writtenContent.length);
      console.log('验证: 文件内容前100字符:', writtenContent.substring(0, 100));
      
      // 检查是否还有原始内容残留
      if (writtenContent.includes('天阙') || writtenContent.includes('Xiao-V2board')) {
        console.log('警告: 检测到原始配置文件内容残留！');
      } else {
        console.log('配置文件替换成功，无原始内容残留');
      }
      console.log('=== 配置文件生成完成 ===');
    } catch (configError) {
      console.error('配置文件生成失败:', configError);
      // 不抛出错误，继续构建过程
      console.log('配置文件生成失败，但继续构建过程');
    }

    // 处理Logo文件
    if (logoFile) {
      console.log('=== 开始处理Logo文件 ===');
      try {
        const logoPath = path.join(buildDir, 'public', 'images', 'logo.png');
        console.log('Logo目标路径:', logoPath);
        
        // 确保目录存在
        await fs.ensureDir(path.dirname(logoPath));
        
        // 写入logo文件
        await fs.writeFile(logoPath, logoFile.buffer);
        console.log('Logo文件写入完成');
        
        // 验证文件是否写入成功
        const logoExists = await fs.pathExists(logoPath);
        if (logoExists) {
          const stats = await fs.stat(logoPath);
          console.log('Logo文件验证成功，文件大小:', stats.size, '字节');
        } else {
          console.log('警告: Logo文件写入后未找到');
        }
      } catch (logoError) {
        console.error('Logo文件处理失败:', logoError);
        // 不抛出错误，继续构建过程
        console.log('Logo文件处理失败，但继续构建过程');
      }
    } else {
      console.log('未提供Logo文件，使用默认Logo');
    }

    // 在打包之前验证配置文件
    console.log('=== 打包前配置文件验证 ===');
    try {
      const configPath = path.join(buildDir, 'src', 'config', 'index.js');
      const finalConfigContent = await fs.readFile(configPath, 'utf8');
      
      console.log('最终配置文件内容长度:', finalConfigContent.length);
      console.log('配置文件前200字符:', finalConfigContent.substring(0, 200));
      
      // 检查关键配置是否被正确替换
      const configChecks = [
        { name: 'PANEL_TYPE', check: (content) => content.includes(configData.PANEL_TYPE || '') },
        { name: 'SITE_CONFIG.siteName', check: (content) => content.includes(configData.SITE_CONFIG?.siteName || '') },
        { name: 'SITE_CONFIG.siteDescription', check: (content) => content.includes(configData.SITE_CONFIG?.siteDescription || '') },
        { name: 'API_CONFIG.baseURL', check: (content) => content.includes(configData.API_CONFIG?.baseURL || '') }
      ];
      
      let allChecksPassed = true;
      for (const check of configChecks) {
        const passed = check.check(finalConfigContent);
        console.log(`配置检查 ${check.name}: ${passed ? '✓ 通过' : '✗ 失败'}`);
        if (!passed) allChecksPassed = false;
      }
      
      if (allChecksPassed) {
        console.log('✓ 所有配置文件检查通过，可以开始打包');
      } else {
        console.log('✗ 配置文件检查失败，但继续打包过程');
      }
      
    } catch (verifyError) {
      console.error('配置文件验证失败:', verifyError);
      console.log('继续打包过程');
    }

    console.log('=== 替换外部配置文件 ===');
    
    // 替换src/config/index.js文件
    const configJsFile = path.join(buildDir, 'src', 'config', 'index.js');
    console.log('配置文件路径:', configJsFile);
    
    if (await fs.pathExists(configJsFile)) {
      console.log('生成新的配置文件...');
      
      // 生成新的配置文件内容
      const newConfigContent = `/**
 * 外部配置文件
 * 由EZ-Theme构建器自动生成
 * index.html 中可以搜索 EZ 将其替换为您的网站名称
 * logo 摆放位置为 images/logo.png
 */

export const config = ${JSON.stringify(configData, null, 4)};

window.EZ_CONFIG = config;`;
      
      await fs.writeFile(configJsFile, newConfigContent);
      console.log('外部配置文件替换完成');
      
      // 重新构建项目以包含新的配置文件
      console.log('=== 重新构建项目 ===');
      await new Promise((resolve, reject) => {
        exec('npm run build', { 
          cwd: buildDir,
          env: { ...process.env, VUE_APP_CONFIGJS: 'false' }
        }, (error, stdout, stderr) => {
          if (error) {
            console.error('重新构建错误:', error);
            console.error('重新构建错误输出:', stderr);
            reject(error);
            return;
          }
          console.log('项目重新构建完成');
          console.log('重新构建输出:', stdout);
          resolve(stdout);
        });
      });
    } else {
      console.log('未找到配置文件:', configJsFile);
    }

    console.log('开始创建ZIP文件');
    // 创建ZIP文件
    const output = fs.createWriteStream(path.join(outputDir, `${buildId}.zip`));
    const archive = archiver('zip', { zlib: { level: 9 } });

    output.on('close', () => {
      console.log('ZIP文件创建完成');
    });

    archive.on('error', (err) => {
      console.error('ZIP创建错误:', err);
      throw err;
    });

    archive.pipe(output);
    archive.directory(path.join(buildDir, 'dist'), false);
    await archive.finalize();
    console.log('ZIP文件打包完成');

    console.log('更新构建状态为完成');
    // 更新构建状态为完成
    const downloadUrl = `/api/builds/${buildId}/download`;
    db.run('UPDATE builds SET status = ?, download_url = ? WHERE build_id = ?', 
      ['completed', downloadUrl, buildId]);

    console.log('清理临时文件');
    // 清理临时文件
    await fs.remove(buildDir);
    console.log('构建完成！');

  } catch (error) {
    console.error('构建失败:', error);
    console.error('错误详情:', error.message);
    db.run('UPDATE builds SET status = ? WHERE build_id = ?', ['failed', buildId]);
    console.log('构建状态已更新为失败');
  }

}

// 静态文件服务 - 前端构建文件
app.use('/', express.static(path.join(__dirname, 'frontend', 'dist'), {
  setHeaders: (res, filePath) => {
    res.setHeader('Cross-Origin-Embedder-Policy', 'unsafe-none');
    res.setHeader('Cross-Origin-Opener-Policy', 'unsafe-none');
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    // 强制使用HTTP
    res.setHeader('Strict-Transport-Security', 'max-age=0');
  }
}));

// 健康检查路由
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development'
  });
});

// 快速启动检查路由
app.get('/api/ping', (req, res) => {
  res.status(200).send('pong');
});

// 测试路由
app.get('/test', (req, res) => {
  res.sendFile(path.join(__dirname, 'test.html'));
});

// 调试路由
app.get('/debug', (req, res) => {
  res.sendFile(path.join(__dirname, 'debug.html'));
});

// Vue测试路由
app.get('/vue-test', (req, res) => {
  res.sendFile(path.join(__dirname, 'simple-test.html'));
});

// 前端构建调试路由
app.get('/debug-frontend', (req, res) => {
  res.sendFile(path.join(__dirname, 'debug-frontend.html'));
});

// 所有其他路由都返回前端页面（SPA支持）
app.get('*', (req, res) => {
  // 设置正确的Content-Type
  res.setHeader('Content-Type', 'text/html');
  res.sendFile(path.join(__dirname, 'frontend', 'dist', 'index.html'));
});

// 启动服务器
app.listen(PORT, '0.0.0.0', () => {
  console.log(`服务器运行在端口 ${PORT}`);
  console.log(`管理后台: http://localhost:${PORT}/admin`);
  console.log(`用户界面: http://localhost:${PORT}`);
});

module.exports = app;

