const express = require('express');
const cors = require('cors');
const axios = require('axios');
const querystring = require('querystring');
const mqtt = require('mqtt');
require('dotenv').config();

const {
  initDB,
  saveSmsCode,
  verifySmsCode,
  findOrCreateUserByPhone,
  findUserByPhoneAndPassword,
  registerUserWithPassword
} = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 日志中间件
app.use((req, res, next) => {
  console.log(`[${new Date().toLocaleTimeString()}] ${req.method} ${req.url}`);
  next();
});

// 健康检查与状态接口
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    message: '云栖酒店后端服务运行正常',
    timestamp: Date.now()
  });
});

// ==================== MQTT 物联网设备服务 ====================
const MQTT_BROKER_URL = process.env.MQTT_BROKER_URL || 'mqtt://192.168.10.111:1883';
let mqttClient = null;
let isMqttConnected = false;

// 实时硬件与设备状态缓存 (保持与STM32传感器上报及App控制同步)
const deviceState = {
  temp: 24.0,       // 实时温度 (℃)
  humi: 50.0,       // 实时湿度 (%)
  gas: 1,           // 烟雾/燃气 (1: 正常, 0: 报警)
  human: 0,         // 人体感应 (1: 有人, 0: 无人)
  light: 0,         // 主灯/大灯状态 (1: 开, 0: 关)
  motor: 0,         // 排风电机 (1: 开, 0: 关)
  gate: 0,          // 闸道状态 (1: 开, 0: 关)
  beep: 0,          // 蜂鸣器 (1: 响, 0: 停)
  lastUpdated: Date.now()
};

function initMqtt() {
  console.log(`[MQTT] 正在尝试连接 MQTT Broker: ${MQTT_BROKER_URL}`);
  try {
    mqttClient = mqtt.connect(MQTT_BROKER_URL, {
      clientId: 'hotel_server_' + Math.random().toString(16).substring(2, 8),
      username: 'haha',
      password: '',
      reconnectPeriod: 3000,
      connectTimeout: 4000
    });

    mqttClient.on('connect', () => {
      isMqttConnected = true;
      console.log(`[MQTT] ★ 成功连通 EMQX Broker (${MQTT_BROKER_URL})！`);
      mqttClient.subscribe('sensorData', { qos: 0 }, (err) => {
        if (!err) {
          console.log('[MQTT] ★ 已成功订阅硬件数据上报主题: sensorData');
        }
      });
    });

    mqttClient.on('message', (topic, message) => {
      if (topic === 'sensorData') {
        try {
          const payloadStr = message.toString();
          const parsed = JSON.parse(payloadStr);
          if (parsed.temp !== undefined) deviceState.temp = Number(parsed.temp);
          if (parsed.humi !== undefined) deviceState.humi = Number(parsed.humi);
          if (parsed.gas !== undefined) deviceState.gas = Number(parsed.gas);
          if (parsed.human !== undefined) deviceState.human = Number(parsed.human);
          if (parsed.light !== undefined) deviceState.light = Number(parsed.light);
          if (parsed.motor !== undefined) deviceState.motor = Number(parsed.motor);
          if (parsed.gate !== undefined) deviceState.gate = Number(parsed.gate);
          deviceState.lastUpdated = Date.now();
        } catch (e) {
          console.warn('[MQTT 数据解析警告]:', message.toString());
        }
      }
    });

    mqttClient.on('error', (err) => {
      isMqttConnected = false;
    });

    mqttClient.on('close', () => {
      isMqttConnected = false;
    });
  } catch (err) {
    console.warn('[MQTT 初始化异常]:', err.message);
  }
}

// 统一硬件指令下发函数 (增加防抖，避免硬件板子串口过载)
let lastPubCommand = '';
let lastPubTimestamp = 0;

function sendMqttCommand(cmd) {
  const now = Date.now();
  if (cmd === lastPubCommand && (now - lastPubTimestamp < 250)) {
    return true; // 过滤 250ms 内的重复指令
  }
  lastPubCommand = cmd;
  lastPubTimestamp = now;

  if (mqttClient && isMqttConnected) {
    mqttClient.publish('commandtopic', cmd, { qos: 0 }, (err) => {
      if (err) {
        console.error(`[MQTT 指令下发失败 ${cmd}]:`, err.message);
      } else {
        console.log(`[MQTT ★ 指令成功发送至硬件]: ${cmd}`);
      }
    });
    return true;
  } else {
    console.warn(`[MQTT 提示: Broker暂未连接，指令进入内存仿真模式]: ${cmd}`);
    return false;
  }
}

/**
 * 获取客房 IoT 设备与传感器实时状态
 * GET /api/device/status
 */
app.get('/api/device/status', (req, res) => {
  res.json({
    code: 200,
    message: '获取设备状态成功',
    data: {
      ...deviceState,
      mqttOnline: isMqttConnected
    }
  });
});

/**
 * 设备控制下发接口
 * POST /api/device/control
 * 请求体支持直接 command: "light_on" | "motor_on" | "beep_on" | "gate_open" 等
 * 或结构化: { "device_type": "light", "power": 1 }
 */
app.post('/api/device/control', (req, res) => {
  try {
    const { command, device_type, power, action, room_no } = req.body;
    let targetCmd = command;

    if (!targetCmd && device_type) {
      if (device_type === 'light') {
        targetCmd = (power === 1 || power === true || action === 'on') ? 'light_on' : 'light_off';
      } else if (device_type === 'motor' || device_type === 'fan' || device_type === 'ac') {
        targetCmd = (power === 1 || power === true || action === 'on') ? 'motor_on' : 'motor_off';
      } else if (device_type === 'beep' || device_type === 'curtain' || device_type === 'buzzer') {
        targetCmd = (power === 1 || power === true || action === 'open' || action === 'on') ? 'beep_on' : 'beep_off';
      } else if (device_type === 'gate') {
        if (action === 'test') {
          targetCmd = 'gate_test';
        } else {
          targetCmd = (power === 1 || power === true || action === 'open') ? 'gate_open' : 'gate_close';
        }
      }
    }

    if (!targetCmd) {
      return res.status(400).json({ code: 400, message: '请提供有效的控制指令 (command 或 device_type)' });
    }

    // 闸道动作特殊保护：防止连点冲垮单片机，并确保开闸后准确自动回原位
    if (targetCmd === 'gate_test') {
      if (deviceState.gate === 1) {
        console.log('[闸道保护] 闸道正在开启动作中，已过滤重复点击');
        return res.json({
          code: 200,
          message: '闸道正在动作中，请勿重复点击',
          data: { command: targetCmd, published: false, currentState: deviceState }
        });
      }
      deviceState.gate = 1;
      deviceState.lastUpdated = Date.now();
      sendMqttCommand('gate_open');
      console.log('[闸道控制] ★ 已下发 gate_open 开门，2.5秒后将自动下发 gate_close 关门回原位');

      setTimeout(() => {
        sendMqttCommand('gate_close');
        deviceState.gate = 0;
        deviceState.lastUpdated = Date.now();
        console.log('[闸道控制] ★ 已下发 gate_close，闸道已成功回原位闭合！');
      }, 2500);

      return res.json({
        code: 200,
        message: '闸道已开启，2.5秒后自动回原位闭合',
        data: {
          command: targetCmd,
          published: true,
          mqttOnline: isMqttConnected,
          currentState: deviceState
        }
      });
    }

    // 立即更新内存状态，保证界面秒级回显
    if (targetCmd === 'light_on') deviceState.light = 1;
    if (targetCmd === 'light_off') deviceState.light = 0;
    if (targetCmd === 'motor_on') deviceState.motor = 1;
    if (targetCmd === 'motor_off') deviceState.motor = 0;
    if (targetCmd === 'beep_on') deviceState.beep = 1;
    if (targetCmd === 'beep_off') deviceState.beep = 0;
    if (targetCmd === 'gate_open') deviceState.gate = 1;
    if (targetCmd === 'gate_close') deviceState.gate = 0;
    deviceState.lastUpdated = Date.now();

    const published = sendMqttCommand(targetCmd);

    return res.json({
      code: 200,
      message: `指令 [${targetCmd}] 已执行`,
      data: {
        command: targetCmd,
        published: published,
        mqttOnline: isMqttConnected,
        currentState: deviceState
      }
    });
  } catch (error) {
    console.error('设备控制处理异常:', error);
    return res.status(500).json({ code: 500, message: '设备控制失败', error: error.message });
  }
});


/**
 * 发送短信验证码接口
 * POST /api/sms/send
 * 请求体: { "phone": "19548157345" }
 */
app.post('/api/sms/send', async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone || String(phone).trim().length < 6) {
      return res.status(400).json({
        code: 400,
        message: '请输入正确的手机号码'
      });
    }

    const cleanPhone = String(phone).trim();
    // 生成6位随机验证码
    const generatedCode = String(Math.floor(100000 + Math.random() * 900000));
    
    // 保存至 MySQL 数据库
    await saveSmsCode(cleanPhone, generatedCode, 5);

    // 阿里云快证短信 API 配置
    const appCode = process.env.ALIYUN_SMS_APPCODE || 'b357e997ab0a4bc9a407110de08a62c4';
    const templateId = process.env.ALIYUN_SMS_TEMPLATE_ID || '';
    
    let aliyunResult = null;
    let smsSent = false;
    let smsNotice = '';

    // 如果配置了模板或者有AppCode，发起阿里云市场请求
    if (appCode) {
      try {
        const payload = querystring.stringify({
          mobile: cleanPhone,
          templateId: templateId || 'test', // 如果用户还没报备模板，使用默认测试
          value: generatedCode
        });

        const response = await axios.post(
          'https://kzsms.market.alicloudapi.com/api/sms/send',
          payload,
          {
            headers: {
              'Authorization': `APPCODE ${appCode}`,
              'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
            },
            timeout: 5000
          }
        );

        aliyunResult = response.data;
        if (response.data && (response.data.code === '200' || response.data.code === 200 || response.data.success === true)) {
          smsSent = true;
          smsNotice = '短信验证码已通过阿里云发送至您的手机';
        } else {
          smsNotice = `阿里云返回: ${response.data.msg || JSON.stringify(response.data)}`;
        }
      } catch (smsErr) {
        const errDetail = smsErr.response?.data || smsErr.message;
        console.warn('[阿里云短信API调用提示]:', errDetail);
        smsNotice = '短信通道正在审核/调试模式中';
      }
    }

    console.log(`[验证码生成] 手机号: ${cleanPhone}, 验证码: ${generatedCode} (有效期5分钟)`);

    // 返回成功，开发调试模式附带 devCode 方便直接填入体验
    return res.json({
      code: 200,
      message: smsSent ? '验证码发送成功' : '验证码已生成',
      data: {
        phone: cleanPhone,
        smsSent: smsSent,
        notice: smsNotice,
        // 开发体验模式：直接返回验证码方便一键测试，即使短信套餐只有4条也不受阻碍
        devCode: generatedCode
      }
    });

  } catch (error) {
    console.error('发送验证码异常:', error);
    return res.status(500).json({
      code: 500,
      message: '服务器处理验证码失败',
      error: error.message
    });
  }
});

/**
 * 手机号验证码登录接口
 * POST /api/auth/login-code
 * 请求体: { "phone": "19548157345", "code": "123456" }
 */
app.post('/api/auth/login-code', async (req, res) => {
  try {
    const { phone, code } = req.body;
    if (!phone || !code) {
      return res.status(400).json({ code: 400, message: '手机号和验证码不能为空' });
    }

    const cleanPhone = String(phone).trim();
    const cleanCode = String(code).trim();

    // 验证码比对（校验有效性与时效）
    const verifyResult = await verifySmsCode(cleanPhone, cleanCode);
    if (!verifyResult.success) {
      return res.status(400).json({
        code: 400,
        message: verifyResult.message || '验证码错误或已失效'
      });
    }

    // 验证通过，查询或自动注册用户
    const user = await findOrCreateUserByPhone(cleanPhone);

    return res.json({
      code: 200,
      message: '登录成功',
      data: {
        user: {
          id: user.id,
          phone: user.phone,
          name: user.name,
          loginType: 'sms_code'
        }
      }
    });

  } catch (error) {
    console.error('验证码登录异常:', error);
    return res.status(500).json({
      code: 500,
      message: '登录服务异常',
      error: error.message
    });
  }
});

/**
 * 账号密码登录接口
 * POST /api/auth/login-password
 * 请求体: { "phone": "123456", "password": "..." }
 */
app.post('/api/auth/login-password', async (req, res) => {
  try {
    const { phone, password } = req.body;
    if (!phone || !password) {
      return res.status(400).json({ code: 400, message: '账号和密码不能为空' });
    }

    const cleanPhone = String(phone).trim();
    const cleanPwd = String(password).trim();

    // 兼容内置体验账号 123456 / 123456
    let user = await findUserByPhoneAndPassword(cleanPhone, cleanPwd);
    
    // 如果数据库暂时未连通或未查到，但输入的是 123456/123456 默认兜底
    if (!user && cleanPhone === '123456' && cleanPwd === '123456') {
      user = { id: 1, phone: '123456', name: '测试管理员' };
    }

    if (!user) {
      return res.status(401).json({
        code: 401,
        message: '手机号或密码错误，请重新输入'
      });
    }

    return res.json({
      code: 200,
      message: '登录成功',
      data: {
        user: {
          id: user.id,
          phone: user.phone,
          name: user.name,
          loginType: 'password'
        }
      }
    });

  } catch (error) {
    console.error('密码登录异常:', error);
    return res.status(500).json({
      code: 500,
      message: '登录服务异常',
      error: error.message
    });
  }
});

/**
 * 账号注册接口（设置密码 + 确认密码 + 校验验证码 + 写入数据库）
 * POST /api/auth/register
 * 请求体: { "phone": "152...", "password": "...", "code": "..." }
 */
app.post('/api/auth/register', async (req, res) => {
  try {
    const { phone, password, code } = req.body;
    if (!phone || !password || !code) {
      return res.status(400).json({ code: 400, message: '手机号、密码和验证码均不能为空' });
    }

    const cleanPhone = String(phone).trim();
    const cleanPwd = String(password).trim();
    const cleanCode = String(code).trim();

    if (cleanPhone.length < 6) {
      return res.status(400).json({ code: 400, message: '请输入正确的手机号码' });
    }

    if (cleanPwd.length < 6) {
      return res.status(400).json({ code: 400, message: '密码长度不能少于6位' });
    }

    // 1. 验证短信验证码时效与准确性
    const verifyResult = await verifySmsCode(cleanPhone, cleanCode);
    if (!verifyResult.success) {
      // 若处于开发联调模式且验证码为6位数字，允许通过
      if (!(process.env.DEV_MODE === 'true' && cleanCode.length === 6)) {
        return res.status(400).json({
          code: 400,
          message: verifyResult.message || '验证码错误或已失效'
        });
      }
    }

    // 2. 注册并存入数据库 users 表
    const regResult = await registerUserWithPassword(cleanPhone, cleanPwd);
    if (!regResult.success) {
      return res.status(400).json({
        code: 400,
        message: regResult.message
      });
    }

    console.log(`[用户注册成功] 手机号: ${cleanPhone} 密码已加密存入数据库 users 表！`);

    return res.json({
      code: 200,
      message: '注册成功',
      data: {
        user: {
          id: regResult.user.id,
          phone: regResult.user.phone,
          name: regResult.user.name,
          loginType: 'register'
        }
      }
    });

  } catch (error) {
    console.error('注册异常:', error);
    return res.status(500).json({
      code: 500,
      message: '注册服务异常',
      error: error.message
    });
  }
});

// 启动服务
async function startServer() {
  await initDB();
  initMqtt();
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`===============================================`);
    console.log(`云栖酒店后端服务已启动: http://localhost:${PORT}`);
    console.log(`局域网/模拟器访问地址: http://127.0.0.1:${PORT}`);
    console.log(`===============================================`);
  });
}

startServer();
