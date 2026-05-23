#!/usr/bin/env node
/**
 * Just · 小红书发布 Agent
 * ============================================================
 * 通用发布管道：接受任意 HTML 文件，截图 → 预览 → 确认 → 发布
 *
 * 用法：
 *   node agent.js --html <file> --title "标题" --content "正文" --tags "a,b,c"
 *
 * 参数：
 *   --html <path>       必填：HTML 文件路径（含 .card-page 元素）
 *   --title "..."       帖子标题（小红书发布用）
 *   --content "..."     帖子正文（小红书发布用，放在图片下方）
 *   --tags "a,b,c"      话题标签，英文逗号分隔
 *   --no-original       不声明原创（默认声明）
 *   --no-publish        只截图预览，不发布
 *
 * 工作流：
 *   1. Puppeteer 打开 HTML，截图每个 .card-page 元素
 *   2. 自动打开图片预览（macOS Preview.app）
 *   3. 展示发布摘要，等待终端确认 [y/N]
 *   4. 发布到小红书（通过 MCP 服务，需提前运行 ./xiaohongshu-mcp）
 */

import puppeteer from 'puppeteer';
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StreamableHTTPClientTransport } from '@modelcontextprotocol/sdk/client/streamableHttp.js';
import readline from 'readline';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { exec } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const MCP_URL   = 'http://localhost:18060/mcp';
const IMAGES_DIR = path.join(__dirname, 'images');

// ─── CLI 参数解析 ──────────────────────────────────────────────

function parseArgs() {
  const argv = process.argv.slice(2);
  const get  = flag => { const i = argv.indexOf(flag); return i >= 0 ? argv[i + 1] ?? null : null; };
  const has  = flag => argv.includes(flag);

  const htmlFile = get('--html');
  if (!htmlFile) {
    console.error([
      '',
      '用法: node agent.js --html <file> [选项]',
      '',
      '  --html <path>        HTML 文件路径（必填）',
      '  --title "..."        帖子标题',
      '  --content "..."      帖子正文',
      '  --tags "a,b,c"       话题标签',
      '  --no-original        不声明原创',
      '  --no-publish         只截图预览，不发布',
      '',
    ].join('\n'));
    process.exit(1);
  }

  return {
    htmlFile:   path.resolve(htmlFile),
    title:      get('--title')   ?? 'Just · 研究分享',
    content:    get('--content') ?? '',
    tags:       (get('--tags') ?? '投资,Just').split(',').map(t => t.trim()).filter(Boolean),
    isOriginal: !has('--no-original'),
    noPublish:  has('--no-publish'),
  };
}

// ─── Puppeteer 截图 ────────────────────────────────────────────

async function screenshot(htmlFile) {
  if (!fs.existsSync(htmlFile)) {
    throw new Error(`HTML 文件不存在: ${htmlFile}`);
  }

  if (!fs.existsSync(IMAGES_DIR)) {
    fs.mkdirSync(IMAGES_DIR, { recursive: true });
  }

  console.log(`\n🎨 截图: ${path.basename(htmlFile)}\n`);

  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--font-render-hinting=none'],
  });

  try {
    const page = await browser.newPage();

    // 3x 分辨率，适配高清屏
    await page.setViewport({ width: 430, height: 900, deviceScaleFactor: 3 });

    await page.goto(`file://${htmlFile}`, { waitUntil: 'load', timeout: 30_000 });

    // 等待字体和布局稳定（霞鹜文楷需要时间加载）
    await new Promise(r => setTimeout(r, 2000));

    const cardElements = await page.$$('.card-page');
    const saved = [];

    if (cardElements.length > 0) {
      for (let i = 0; i < cardElements.length; i++) {
        const seq = String(i + 1).padStart(2, '0');
        const imgPath = path.join(IMAGES_DIR, `${seq}-card.png`);
        await cardElements[i].screenshot({ path: imgPath, type: 'png' });
        saved.push(imgPath);
        console.log(`  ✅ ${path.basename(imgPath)}`);
      }
    } else {
      // 没有 .card-page，全页截图
      const imgPath = path.join(IMAGES_DIR, '01-fullpage.png');
      await page.screenshot({ path: imgPath, fullPage: true, type: 'png' });
      saved.push(imgPath);
      console.log(`  ✅ ${path.basename(imgPath)}（全页截图）`);
    }

    console.log(`\n📁 共 ${saved.length} 张图片 → ${IMAGES_DIR}\n`);
    return saved;
  } finally {
    await browser.close();
  }
}

// ─── 预览 ──────────────────────────────────────────────────────

function openPreview(imagePaths) {
  const quoted = imagePaths.map(p => `"${p}"`).join(' ');
  exec(`open ${quoted}`);
}

// ─── 终端确认 ──────────────────────────────────────────────────

function confirm(prompt) {
  return new Promise(resolve => {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    rl.question(prompt, answer => {
      rl.close();
      resolve(answer.trim().toLowerCase());
    });
  });
}

// ─── MCP 工具调用 ──────────────────────────────────────────────

async function callMCP(toolName, toolArgs, timeoutMs = 300_000) {
  const client = new Client({ name: 'just-agent', version: '2.0.0' });
  const transport = new StreamableHTTPClientTransport(new URL(MCP_URL));
  await client.connect(transport);
  try {
    return await client.callTool(
      { name: toolName, arguments: toolArgs },
      undefined,
      { timeout: timeoutMs },
    );
  } finally {
    await client.close().catch(() => {});
  }
}

async function checkLogin() {
  process.stdout.write('🔍 检查登录状态... ');
  try {
    const res = await callMCP('check_login_status', {}, 20_000);
    const ok  = /true|已登录/i.test(JSON.stringify(res));
    console.log(ok ? '✅ 已登录' : '❌ 未登录');
    return ok;
  } catch (e) {
    console.log(`❌ 无法连接 MCP 服务 (${e.message.slice(0, 60)})`);
    console.log('   请先在另一个终端运行: ./xiaohongshu-mcp');
    return false;
  }
}

// ─── 主流程 ────────────────────────────────────────────────────

const opts = parseArgs();

// Step 1: 截图
const imagePaths = await screenshot(opts.htmlFile);

// Step 2: 打开预览
console.log('👀 打开图片预览...');
openPreview(imagePaths);

// Step 3: 展示发布摘要
console.log('─'.repeat(42));
console.log(`标题: ${opts.title}`);
console.log(`标签: ${opts.tags.map(t => '#' + t).join('  ')}`);
console.log(`图片: ${imagePaths.length} 张`);
if (opts.content) {
  const preview = opts.content.slice(0, 80);
  console.log(`正文: ${preview}${opts.content.length > 80 ? '...' : ''}`);
}
console.log('─'.repeat(42) + '\n');

// Step 4: 确认
if (opts.noPublish) {
  console.log('（--no-publish 模式，截图已完成，未发布）');
  process.exit(0);
}

const answer = await confirm('确认发布到小红书？[y/N]  ');
if (answer !== 'y' && answer !== 'yes') {
  console.log('\n已取消。图片保存在 images/ 目录，可手动发布。');
  process.exit(0);
}

// Step 5: 检查登录
console.log('');
const loggedIn = await checkLogin();
if (!loggedIn) {
  console.error('\n请先登录，运行: npm run login\n');
  process.exit(1);
}

// Step 6: 发布
console.log('\n📤 发布中...\n');
const res = await callMCP('publish_content', {
  title:      opts.title,
  content:    opts.content,
  images:     imagePaths,
  tags:       opts.tags,
  is_original: opts.isOriginal,
  visibility: '公开可见',
});

const msg = res?.content?.[0]?.text ?? JSON.stringify(res, null, 2);
console.log('✅ 发布结果:');
console.log(msg);
