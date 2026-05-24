#!/usr/bin/env node
/**
 * 小红书自动发布脚本
 *
 * 工作流程:
 *   1. 启动 xiaohongshu-mcp Docker 容器 (npm run start-mcp)
 *   2. 首次登录: npm run login  → 扫码
 *   3. 发布:     npm run publish → 渲染卡片 + 自动发布
 *
 * 命令行参数:
 *   --login       获取登录二维码
 *   --check       检查登录状态
 *   --render-only 只渲染图片，不发布
 *   (无参数)      渲染 + 发布
 */

import puppeteer from 'puppeteer';
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StreamableHTTPClientTransport } from '@modelcontextprotocol/sdk/client/streamableHttp.js';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { exec } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ─── 配置 ─────────────────────────────────────────────────────────────────────

const MCP_URL = 'http://localhost:18060/mcp';
const IMAGES_DIR = path.join(__dirname, 'images');
const WORKSPACE_ROOT = '/Users/qisd/Documents/development/ai/thinking';
const CARDS_HTML = path.join(WORKSPACE_ROOT, 'Just学投资', 'spaceX研究', 'cards.html');
const ARTICLE_MD = path.join(WORKSPACE_ROOT, 'Just学投资', 'spaceX研究', 'spaceX-商业分析-2026-05-24.md');
const MAX_TITLE_CHARS = 28;
const MAX_CONTENT_CHARS = 1000;
const ARTICLE_TAGS = ['SpaceX', '商业模式', '利润分析', '卫星互联网', '火箭发射', '长期主义', '投资研究', 'Just60投资笔记'];

/** 要截图的卡片 ID（对应 cards.html 中 .card 的 id 属性） */
const CARDS = [
  { id: 'c1', name: '01-封面' },
  { id: 'c2', name: '02-利润数据' },
  { id: 'c3', name: '03-收入结构' },
  { id: 'c4', name: '04-估值框架' },
  { id: 'c5', name: '05-竞争格局' },
  { id: 'c6', name: '06-多空论点' },
  { id: 'c7', name: '07-宏观评级' },
  { id: 'c8', name: '08-结论与跟踪' },
  { id: 'c9', name: '09-免责声明' },
];

/** 小红书发布内容配置 — 按需修改 */
const POST = {
  title: 'SpaceX 商业分析：远景很大，利润为王',
  content: [
    '火星计划很宏大，这点没人反对。',
    '但把它当一家企业看，最关键还是商业模式和利润闭环。',
    '',
    '我这次把 SpaceX 拆成四层：发射服务、Starlink、Starship、新业务协同。',
    '看到最清楚的一点是：现金流主要靠前两层，估值弹性主要靠后两层。',
    '',
    '最值得盯的不是口号，而是三个数字：',
    '1) Starlink 企业/政企占比',
    '2) Starship 发射频次和单次成本',
    '3) 新业务协同收入验证率',
    '',
    '一句话总结：远景给上限，现金流给底线。',
    '没有利润闭环，宏大叙事很难长期兑现。',
    '',
    '⚠️ 以上仅为个人研究，不构成投资建议。',
  ].join('\n'),
  tags: ['SpaceX', '商业分析', '利润为王', '卫星互联网', '火箭经济', '长期主义', '投资研究', 'Just60投资笔记'],
  is_original: true,
  visibility: '公开可见',
};

function clampTitle(title, maxChars = MAX_TITLE_CHARS) {
  const chars = Array.from((title || '').trim());
  if (chars.length <= maxChars) return title;
  return `${chars.slice(0, Math.max(0, maxChars - 1)).join('')}…`;
}

function clampContent(content, maxChars = MAX_CONTENT_CHARS) {
  const chars = Array.from((content || '').trim());
  if (chars.length <= maxChars) return content;
  return `${chars.slice(0, Math.max(0, maxChars - 1)).join('')}…`;
}

function extractTitleFromMarkdown(markdown) {
  const line = markdown.split('\n').find((l) => l.trim().startsWith('# '));
  return (line ? line.replace(/^#\s+/, '').trim() : '个人思考').replace(/：人要何去何从\s*$/, '');
}

function formatMarkdownForXhs(markdown) {
  const lines = markdown.split('\n');
  const output = [];
  let firstParagraph = '';

  for (const raw of lines) {
    const line = raw.trim();
    if (!line) {
      output.push('');
      continue;
    }
    if (line.startsWith('# ')) continue;
    if (/^\*仅为个人思考/.test(line)) continue;

    if (line.startsWith('## ')) {
      output.push(`【${line.replace(/^##\s+/, '')}】`);
      continue;
    }

    let clean = line
      .replace(/\*\*(.*?)\*\*/g, '$1')
      .replace(/^[-*]\s+/, '• ');
    if (!firstParagraph && !clean.startsWith('【')) {
      firstParagraph = clean;
      continue;
    }
    output.push(clean);
  }

  const compact = [];
  for (const l of output) {
    if (l === '' && compact[compact.length - 1] === '') continue;
    compact.push(l);
  }

  const body = compact.join('\n').trim();
  const intro = [
    '今天记一条最近反复在想的判断。',
    firstParagraph ? `\n${firstParagraph}` : '',
    '\n这不是结论文，只是把正在发生的变化先记下来。',
    '\n——',
    '',
  ].join('\n');

  return `${intro}${body}\n\n——\n以上仅为个人思考，不构成投资建议或职业建议`;
}

async function renderArticleCover(title) {
  if (!fs.existsSync(IMAGES_DIR)) {
    fs.mkdirSync(IMAGES_DIR, { recursive: true });
  }

  const coverPath = path.join(IMAGES_DIR, 'article-cover.png');
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--font-render-hinting=none'],
  });

  try {
    const page = await browser.newPage();
    await page.setViewport({ width: 430, height: 650, deviceScaleFactor: 3 });
    const safeTitle = title
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');

    await page.setContent(`
      <html><head><meta charset="UTF-8" />
      <style>
        * { box-sizing: border-box; }
        body {
          margin: 0;
          width: 430px;
          height: 650px;
          display: flex;
          align-items: center;
          justify-content: center;
          background: linear-gradient(160deg, #f1f1f1 0%, #d9d9d9 100%);
          font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", "Microsoft YaHei", sans-serif;
          color: #111;
          position: relative;
        }
        .wrap {
          width: 84%;
          text-align: center;
        }
        h1 {
          margin: 0;
          font-size: 42px;
          line-height: 1.28;
          letter-spacing: -0.02em;
          font-weight: 800;
          color: #111;
        }
        .brand {
          position: absolute;
          bottom: 28px;
          left: 0;
          right: 0;
          text-align: center;
          font-size: 14px;
          color: #666;
          letter-spacing: .04em;
        }
      </style>
      </head><body>
        <div class="wrap"><h1>${safeTitle}</h1></div>
        <div class="brand">Just 60 · 个人思考</div>
      </body></html>
    `, { waitUntil: 'load' });

    await page.screenshot({ path: coverPath, type: 'png' });
    return coverPath;
  } finally {
    await browser.close();
  }
}

function buildArticlePayload() {
  const markdown = fs.readFileSync(ARTICLE_MD, 'utf8');
  const baseTitle = extractTitleFromMarkdown(markdown);
  return {
    title: baseTitle.replace(/：人要何去何从\s*$/, '').trim(),
    content: formatMarkdownForXhs(markdown),
    tags: ARTICLE_TAGS,
    is_original: true,
    visibility: '公开可见',
  };
}

// ─── MCP 工具调用 ─────────────────────────────────────────────────────────────

async function callTool(toolName, toolArgs = {}, timeoutMs = 60_000) {
  const client = new Client({ name: 'xhs-publisher', version: '1.0.0' });
  const transport = new StreamableHTTPClientTransport(new URL(MCP_URL), {
    requestOptions: {
      headersTimeout: 600_000,  // 10分钟 headers 超时
      bodyTimeout: 600_000,     // 10分钟 body 超时
    }
  });
  await client.connect(transport);
  try {
    return await client.callTool(
      { name: toolName, arguments: toolArgs },
      undefined,
      { timeout: timeoutMs },
    );
  } finally {
    await client.close().catch(() => { });
  }
}

// ─── 登录 ─────────────────────────────────────────────────────────────────────

async function checkMCPService() {
  try {
    const res = await callTool('check_login_status');
    return true;
  } catch (e) {
    return false;
  }
}

async function checkLogin() {
  process.stdout.write('🔍 检查登录状态... ');
  try {
    const res = await callTool('check_login_status');
    const text = JSON.stringify(res);
    const ok = /true|已登录|logged/i.test(text);
    console.log(ok ? '✅ 已登录' : '❌ 未登录');
    return ok;
  } catch (e) {
    console.log(`❌ 无法连接 MCP 服务 (${e.message})`);
    console.log('   请先运行: npm run start-mcp');
    return false;
  }
}

async function showLoginQR() {
  console.log('📱 获取小红书登录二维码...\n');
  const res = await callTool('get_login_qrcode');
  const content = res?.content ?? [];

  // 打印文字提示（通常是截止时间）
  const textItem = content.find(c => c.type === 'text');
  if (textItem) console.log(textItem.text);

  // 提取 base64 图片数据（type=image 优先，其次尝试 text 里的 data URI）
  const imgItem = content.find(c => c.type === 'image');
  const rawData = imgItem?.data ?? imgItem?.text ?? '';
  const base64 = rawData.replace(/^data:image\/\w+;base64,/, '');

  if (base64.length > 100) {
    const qrPath = path.join(__dirname, 'qr-login.png');
    fs.writeFileSync(qrPath, Buffer.from(base64, 'base64'));
    console.log(`✅ 二维码已保存至: ${qrPath}`);
    exec(`open "${qrPath}"`);  // macOS 自动打开
    console.log('👆 请用小红书 App 扫码登录');
    console.log('⚠️  注意：扫码期间不要在浏览器网页端登录同一账号，否则会被踢出\n');
  } else {
    // 纯文字响应（部分版本直接返回文字）
    console.log('二维码响应:', JSON.stringify(res, null, 2));
  }
}

async function waitForLogin(maxWaitSeconds = 120) {
  console.log('⏳ 等待扫码登录...');
  const startTime = Date.now();

  while (Date.now() - startTime < maxWaitSeconds * 1000) {
    await new Promise(r => setTimeout(r, 3000)); // 每3秒检查一次

    try {
      const res = await callTool('check_login_status');
      const text = JSON.stringify(res);
      if (/true|已登录|logged/i.test(text)) {
        console.log('✅ 登录成功！\n');
        return true;
      }
    } catch (e) {
      // 忽略检查错误，继续轮询
    }
  }

  console.log('❌ 登录超时，请重新运行 npm run login\n');
  return false;
}

// ─── 渲染卡片 ─────────────────────────────────────────────────────────────────

async function renderCards() {
  console.log(`\n🎨 渲染卡片`);
  console.log(`   来源: ${CARDS_HTML}`);
  console.log(`   输出: ${IMAGES_DIR}\n`);

  if (!fs.existsSync(IMAGES_DIR)) {
    fs.mkdirSync(IMAGES_DIR, { recursive: true });
  }

  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--font-render-hinting=none'],
  });

  try {
    const page = await browser.newPage();

    // 模拟 iPhone 15 Pro 高清屏（deviceScaleFactor=3 → 3x 图片）
    await page.setViewport({ width: 430, height: 900, deviceScaleFactor: 3 });

    await page.goto(`file://${CARDS_HTML}`, { waitUntil: 'load', timeout: 30_000 });

    // 等待字体和布局稳定
    await new Promise(r => setTimeout(r, 1500));

    const saved = [];

    for (const card of CARDS) {
      const el = await page.$(`#${card.id}`);
      if (!el) {
        console.warn(`  ⚠️  找不到 #${card.id}，跳过`);
        continue;
      }
      const imgPath = path.join(IMAGES_DIR, `${card.name}.png`);
      await el.screenshot({ path: imgPath, type: 'png' });
      saved.push(imgPath);
      console.log(`  ✅ ${card.name}.png`);
    }

    console.log(`\n📁 共渲染 ${saved.length} 张图片\n`);
    return saved;
  } finally {
    await browser.close();
  }
}

// ─── 定时发布 ─────────────────────────────────────────────────────────────────

function getScheduledTime() {
  const now = new Date();
  const hour = now.getHours();

  // 如果当前是下午（12:00-22:00），定时到今天 20:30
  if (hour >= 12 && hour < 22) {
    const scheduled = new Date(now);
    scheduled.setHours(20, 30, 0, 0);

    // 如果已经过了 20:30，定时到明天早上 8:30
    if (now > scheduled) {
      scheduled.setDate(scheduled.getDate() + 1);
      scheduled.setHours(8, 30, 0, 0);
    }
    return scheduled;
  }

  // 如果当前是晚上（22:00-24:00）或凌晨（0:00-12:00），定时到今天或明天早上 8:30
  const scheduled = new Date(now);
  scheduled.setHours(8, 30, 0, 0);

  // 如果已经过了今天 8:30，定时到明天
  if (now > scheduled) {
    scheduled.setDate(scheduled.getDate() + 1);
  }

  return scheduled;
}

function formatScheduledTime(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hour = String(date.getHours()).padStart(2, '0');
  const minute = String(date.getMinutes()).padStart(2, '0');

  return `${year}-${month}-${day} ${hour}:${minute}`;
}

// ─── 发布 ─────────────────────────────────────────────────────────────────────

async function publish(hostPaths, scheduled = false, postPayload = POST) {
  const safeTitle = clampTitle(postPayload.title);
  if (safeTitle !== postPayload.title) {
    console.log(`✂️ 标题超长，已自动截断为: ${safeTitle}`);
  }

  const payload = {
    ...postPayload,
    title: safeTitle,
    content: clampContent(postPayload.content),
  };

  if (payload.content !== postPayload.content) {
    console.log(`✂️ 正文超长，已自动截断到 ${MAX_CONTENT_CHARS} 字以内`);
  }

  const scheduledTime = scheduled ? getScheduledTime() : null;

  if (scheduledTime) {
    const timeStr = formatScheduledTime(scheduledTime);
    console.log(`⏰ 定时发布: ${timeStr}`);
    console.log(`   标题: ${payload.title}`);
    console.log(`   图片: ${hostPaths.length} 张\n`);
  } else {
    console.log('📤 立即发布到小红书...');
    console.log(`   标题: ${payload.title}`);
    console.log(`   图片: ${hostPaths.length} 张\n`);
  }

  const res = await callTool('publish_content', {
    ...payload,
    images: hostPaths,
    scheduled_time: scheduledTime ? formatScheduledTime(scheduledTime) : undefined,
  }, 600_000);  // 发布涉及图片上传 + 浏览器自动化，需要更长时间（10分钟）

  const msg = res?.content?.[0]?.text ?? JSON.stringify(res, null, 2);
  console.log('📊 发布结果:');
  console.log(msg);
}

// ─── 入口 ─────────────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const articleMode = args.includes('--article');

if (args.includes('--login')) {
  // 登录流程：显示二维码 → 自动轮询检测登录状态
  await showLoginQR();
  const success = await waitForLogin();
  if (!success) {
    process.exit(1);
  }
} else if (args.includes('--check')) {
  // 检查 MCP 服务和登录状态
  console.log('🔧 检查 MCP 服务...');
  const mcpOk = await checkMCPService();
  if (!mcpOk) {
    console.error('❌ MCP 服务未启动，请运行: npm run start-mcp\n');
    process.exit(1);
  }
  console.log('✅ MCP 服务正常\n');
  await checkLogin();
} else if (args.includes('--render-only')) {
  await renderCards();
} else {
  // 完整流程: 检查 MCP → 检查登录 → 渲染 → 发布
  console.log('🚀 开始发布流程\n');

  // 1. 检查 MCP 服务
  console.log('🔧 检查 MCP 服务...');
  const mcpOk = await checkMCPService();
  if (!mcpOk) {
    console.error('❌ MCP 服务未启动，请运行: npm run start-mcp\n');
    process.exit(1);
  }
  console.log('✅ MCP 服务正常\n');

  // 2. 检查登录状态
  let ok = await checkLogin();
  if (!ok) {
    console.log('\n需要登录，正在获取二维码...\n');
    await showLoginQR();
    ok = await waitForLogin();
    if (!ok) {
      process.exit(1);
    }
  }

  let paths = [];
  let payload = POST;

  if (articleMode) {
    console.log('📝 文章发布模式（默认只生成封面图）');
    payload = buildArticlePayload();
    const coverPath = await renderArticleCover(payload.title);
    paths = [coverPath];
    console.log(`✅ 已生成文章封面: ${coverPath}\n`);
  } else {
    // 3. 渲染图片
    paths = await renderCards();
  }

  // 4. 发布（支持定时）
  const scheduled = args.includes('--scheduled');
  await publish(paths, scheduled, payload);
}
