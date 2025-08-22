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
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

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

  // 生成支付二维码
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

// 检查订单状态
app.get('/api/orders/:orderId/status', authenticateToken, (req, res) => {
  const { orderId } = req.params;

  db.get('SELECT * FROM orders WHERE order_id = ? AND user_id = ?', [orderId, req.user.id], (err, order) => {
    if (err || !order) {
      return res.status(404).json({ error: '订单不存在' });
    }

    res.json({
      order_id: order.order_id,
      amount: order.amount,
      status: order.status,
      created_at: order.created_at
    });
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
app.post('/api/builds/create', authenticateToken, [
  body('config_data').isObject().withMessage('配置数据格式错误')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
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

      const { config_data } = req.body;
      const buildId = `BUILD_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

      // 扣除余额
      db.run('UPDATE users SET credits = credits - ? WHERE id = ?', [pricePerBuild, req.user.id], (err) => {
        if (err) {
          return res.status(500).json({ error: '扣除余额失败' });
        }

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
    });
  });
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
async function processBuild(buildId, configData) {
  try {
    // 更新构建状态为处理中
    db.run('UPDATE builds SET status = ? WHERE build_id = ?', ['processing', buildId]);

    // 创建构建目录
    const buildDir = path.join(__dirname, 'temp', buildId);
    const outputDir = path.join(__dirname, 'builds');
    await fs.ensureDir(buildDir);
    await fs.ensureDir(outputDir);

    // 复制EZ-Theme项目文件
    const ezThemePath = 'E:\\GitHub\\EZ-Theme';
    await fs.copy(ezThemePath, buildDir);

    // 更新配置文件
    const configPath = path.join(buildDir, 'src', 'config', 'index.js');
    let configContent = await fs.readFile(configPath, 'utf8');
    
    // 替换配置
    Object.keys(configData).forEach(key => {
      const value = typeof configData[key] === 'object' ? JSON.stringify(configData[key]) : configData[key];
      configContent = configContent.replace(
        new RegExp(`${key}:\\s*['"][^'"]*['"]`, 'g'),
        `${key}: '${value}'`
      );
    });

    await fs.writeFile(configPath, configContent);

    // 构建项目
    const { exec } = require('child_process');
    await new Promise((resolve, reject) => {
      exec('npm run build', { cwd: buildDir }, (error, stdout, stderr) => {
        if (error) {
          console.error('构建错误:', error);
          reject(error);
          return;
        }
        resolve(stdout);
      });
    });

    // 创建ZIP文件
    const output = fs.createWriteStream(path.join(outputDir, `${buildId}.zip`));
    const archive = archiver('zip', { zlib: { level: 9 } });

    output.on('close', () => {
      console.log('ZIP文件创建完成');
    });

    archive.on('error', (err) => {
      throw err;
    });

    archive.pipe(output);
    archive.directory(path.join(buildDir, 'dist'), false);
    await archive.finalize();

    // 更新构建状态为完成
    const downloadUrl = `/api/builds/${buildId}/download`;
    db.run('UPDATE builds SET status = ?, download_url = ? WHERE build_id = ?', 
      ['completed', downloadUrl, buildId]);

    // 清理临时文件
    await fs.remove(buildDir);

  } catch (error) {
    console.error('构建失败:', error);
    db.run('UPDATE builds SET status = ? WHERE build_id = ?', ['failed', buildId]);
  }
}

// 静态文件服务
app.use(express.static(path.join(__dirname, 'public')));

// 启动服务器
app.listen(PORT, () => {
  console.log(`服务器运行在端口 ${PORT}`);
  console.log(`管理后台: http://localhost:${PORT}/admin`);
  console.log(`用户界面: http://localhost:${PORT}`);
});

module.exports = app;
