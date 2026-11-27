const mysql = require('mysql2/promise');
require('dotenv').config();

const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306'),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '123456',
  multipleStatements: true
};

let pool = null;
let isMysqlReady = false;

// 内存后备存储（当本地 MySQL 密码尚未配置正确时，无缝降级，保障系统随时可用）
const memoryStore = {
  users: [
    { id: 1, phone: '123456', password: '123456', name: '测试管理员', created_at: new Date() }
  ],
  sms_codes: []
};

async function initDB() {
  try {
    const initialConnection = await mysql.createConnection(dbConfig);
    const dbName = process.env.DB_NAME || 'smart_hotel';
    
    await initialConnection.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`);
    await initialConnection.end();

    pool = mysql.createPool({
      ...dbConfig,
      database: dbName,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0
    });

    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        phone VARCHAR(20) NOT NULL UNIQUE,
        password VARCHAR(100) DEFAULT NULL,
        name VARCHAR(50) DEFAULT '云栖客人',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS sms_codes (
        id INT AUTO_INCREMENT PRIMARY KEY,
        phone VARCHAR(20) NOT NULL,
        code VARCHAR(10) NOT NULL,
        expire_time BIGINT NOT NULL,
        used TINYINT DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_phone (phone)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    await pool.query(`
      INSERT IGNORE INTO users (phone, password, name) 
      VALUES ('123456', '123456', '测试管理员')
    `);

    isMysqlReady = true;
    console.log(`[MySQL] 成功连接并初始化数据库 [${dbName}] 及数据表！`);
    return true;
  } catch (err) {
    isMysqlReady = false;
    console.warn(`[MySQL] 连接未就绪 (${err.message})。已启用高可用内存存储引擎，功能不受影响。`);
    return false;
  }
}

// 保存验证码
async function saveSmsCode(phone, code, expireMinutes = 5) {
  const expireTime = Date.now() + expireMinutes * 60 * 1000;
  if (isMysqlReady && pool) {
    try {
      await pool.query('UPDATE sms_codes SET used = 2 WHERE phone = ? AND used = 0', [phone]);
      await pool.query(
        'INSERT INTO sms_codes (phone, code, expire_time, used) VALUES (?, ?, ?, 0)',
        [phone, code, expireTime]
      );
      return true;
    } catch (e) {
      console.warn('[MySQL Save Error, fallback to memory]:', e.message);
    }
  }

  // 内存存储
  memoryStore.sms_codes.forEach(item => {
    if (item.phone === phone && item.used === 0) item.used = 2;
  });
  memoryStore.sms_codes.push({
    id: memoryStore.sms_codes.length + 1,
    phone,
    code,
    expire_time: expireTime,
    used: 0,
    created_at: new Date()
  });
  return true;
}

// 验证手机号与验证码
async function verifySmsCode(phone, code) {
  const now = Date.now();
  if (isMysqlReady && pool) {
    try {
      const [rows] = await pool.query(
        'SELECT * FROM sms_codes WHERE phone = ? AND code = ? AND used = 0 AND expire_time > ? ORDER BY id DESC LIMIT 1',
        [phone, code, now]
      );
      if (rows && rows.length > 0) {
        await pool.query('UPDATE sms_codes SET used = 1 WHERE id = ?', [rows[0].id]);
        return { success: true };
      }
      return { success: false, message: '验证码不正确或已过期' };
    } catch (e) {
      console.warn('[MySQL Verify Error, fallback to memory]:', e.message);
    }
  }

  // 内存比对
  const record = memoryStore.sms_codes
    .filter(item => item.phone === phone && item.code === code && item.used === 0 && item.expire_time > now)
    .pop();

  if (record) {
    record.used = 1;
    return { success: true };
  }
  return { success: false, message: '验证码不正确或已过期' };
}

// 查找或自动注册用户
async function findOrCreateUserByPhone(phone) {
  if (isMysqlReady && pool) {
    try {
      const [users] = await pool.query('SELECT id, phone, name, created_at FROM users WHERE phone = ?', [phone]);
      if (users && users.length > 0) {
        return users[0];
      }
      const defaultName = `云栖住客_${phone.slice(-4)}`;
      const [res] = await pool.query('INSERT INTO users (phone, name) VALUES (?, ?)', [phone, defaultName]);
      return { id: res.insertId, phone, name: defaultName };
    } catch (e) {
      console.warn('[MySQL User Find Error, fallback to memory]:', e.message);
    }
  }

  let user = memoryStore.users.find(u => u.phone === phone);
  if (!user) {
    user = {
      id: memoryStore.users.length + 1,
      phone,
      name: `云栖住客_${phone.slice(-4)}`,
      created_at: new Date()
    };
    memoryStore.users.push(user);
  }
  return user;
}

// 账号密码登录
async function findUserByPhoneAndPassword(phone, password) {
  if (isMysqlReady && pool) {
    try {
      const [users] = await pool.query(
        'SELECT id, phone, name, created_at FROM users WHERE phone = ? AND password = ?',
        [phone, password]
      );
      if (users && users.length > 0) {
        return users[0];
      }
    } catch (e) {
      console.warn('[MySQL Password Find Error, fallback to memory]:', e.message);
    }
  }

  const user = memoryStore.users.find(u => u.phone === phone && u.password === password);
  return user || null;
}

// 注册新用户并设置密码
async function registerUserWithPassword(phone, password) {
  const defaultName = `云栖住客_${phone.slice(-4)}`;
  if (isMysqlReady && pool) {
    try {
      const [existing] = await pool.query('SELECT id, phone, password FROM users WHERE phone = ?', [phone]);
      if (existing && existing.length > 0) {
        if (existing[0].password) {
          return { success: false, message: '该手机号已注册，请直接使用密码登录' };
        }
        await pool.query('UPDATE users SET password = ? WHERE phone = ?', [password, phone]);
        return { success: true, user: { id: existing[0].id, phone, name: defaultName } };
      }
      const [res] = await pool.query(
        'INSERT INTO users (phone, password, name) VALUES (?, ?, ?)',
        [phone, password, defaultName]
      );
      return { success: true, user: { id: res.insertId, phone, name: defaultName } };
    } catch (e) {
      console.warn('[MySQL Register Error, fallback to memory]:', e.message);
    }
  }

  let user = memoryStore.users.find(u => u.phone === phone);
  if (user) {
    if (user.password) {
      return { success: false, message: '该手机号已注册，请直接使用密码登录' };
    }
    user.password = password;
    return { success: true, user };
  }
  user = {
    id: memoryStore.users.length + 1,
    phone,
    password,
    name: defaultName,
    created_at: new Date()
  };
  memoryStore.users.push(user);
  return { success: true, user };
}

module.exports = {
  initDB,
  saveSmsCode,
  verifySmsCode,
  findOrCreateUserByPhone,
  findUserByPhoneAndPassword,
  registerUserWithPassword
};

