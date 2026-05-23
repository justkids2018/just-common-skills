#!/usr/bin/env node
/**
 * 完全自动化的小红书发布脚本
 *
 * 用法：
 *   node auto-publish.js <html-file-path>
 *
 * 示例：
 *   node auto-publish.js ../../个股研究/泡泡玛特/popup-mart-rednote-cards.html
 */

import puppeteer from 'puppeteer';
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StreamableHTTPClientTransport } from '@modelcontextprotocol/sdk/client/streamableHttp.js';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { JSDOM } from 'jsdom';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// 配置
const MCP_URL = 'http://localhost:18060/mcp';
const IMAGES_DIR = path.join(__dirname, 'images');

// 从命令行参数获取 HTML 文件路径
const htmlPath = process.argv[2];
if (!htmlPath) {
  console.error('❌ 请提供 HTML 文件路径');
  console.error('用法: node auto-publish.js <html-file-path>');
  process.exit(1);
}

const CARDS_HTML = path.resolve(htmlPath);

// 1. 读取 HTML 并提取内容
async function extractContent() {
  console.log('📖 读取 HTML 文件...');
  const html = fs.readFileSync(CARDS_HTML, 'utf-8');
  const dom = new JSDOM(html);
  const doc = dom.window.document;

  // 提取标题
  const title = doc.querySelector('title')?.textContent ||
    doc.querySelector('h1')?.textContent ||
    '财务分析案例';

  // 提取卡片
  const cardElements = doc.querySelectorAll('.card-page');
  const cards = Array.from(cardElements).map((card, i) => ({
    id: card.id || `c${i + 1}`,
    title: card.querySelector('h1, h2, .card-title')?.textContent || '',
    content: card.textContent.trim(),
  }));

  console.log(`✅ 提取到 ${cards.length} 张卡片`);
  return { title, cards };
}

// 2. 生成文案
function generateContent(data) {
  const { title, cards } = data;

  // 提取公司名（从标题中）
  const companyMatch = title.match(/[:：](.+?)案例/);
  const company = companyMatch ? companyMatch[1].trim() : '';

  console.log(`📝 生成文案（公司：${company}）...`);

  // 生成正文：每张卡片只取标题行（不展开内容），控制总长度
  const sections = cards.slice(1).map((card, i) => {
    const emoji = ['📈', '🏦', '💵', '🎯', '📝'][i] || '📊';
    const summary = simplifyContent(card.content);
    return `${emoji} ${summary}`;
  }).join('\n');

  const footer = '---\nJust 60 出品 · 60分，刚刚好\n以上仅为学习记录，不构成投资建议';
  const tags = company
    ? `#巴菲特 #价值投资 #投资思维 #投资小白 #Just60`
    : `#巴菲特 #价值投资 #投资思维 #投资小白 #Just60`;

  const intro = company
    ? `用${company}真实数据，学懂三张财务报表。`
    : `听完巴菲特3月31号采访，我记住了3件事。`;

  const rawContent = `${intro}\n\n${sections}\n\n${footer}\n\n${tags}`;
  // 确保不超过 1000 字
  const content = rawContent.length <= 1000 ? rawContent : rawContent.slice(0, 997) + '…';

  return {
    title: title.replace(/\s*\|\s*Just\s*60/, '').trim(),
    content,
    tags: ['巴菲特', '价值投资', '投资思维', '投资小白', 'Just60'].filter(Boolean),
  };
}

// 简化内容（提取关键信息）
function simplifyContent(text) {
  return text
    .replace(/Just 60[^\n]*/g, '')
    .replace(/下载|卡片\s*\d+\/\d+/g, '')
    .trim()
    .split('\n')
    .map(l => l.trim())
    .filter(line => line.length > 4)
    .slice(0, 3)
    .join(' · ');
}

// 3. 渲染图片
async function renderCards() {
  console.log('🎨 渲染卡片图片...');

  if (!fs.existsSync(IMAGES_DIR)) {
    fs.mkdirSync(IMAGES_DIR, { recursive: true });
  }

  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  try {
    const page = await browser.newPage();
    await page.setViewport({ width: 390, height: 650, deviceScaleFactor: 3 });
    await page.goto(`file://${CARDS_HTML}`, { waitUntil: 'load' });
    await new Promise(r => setTimeout(r, 1500));

    const cardElements = await page.$$('.card-page');
    const saved = [];

    for (let i = 0; i < cardElements.length; i++) {
      const imgPath = path.join(IMAGES_DIR, `${String(i + 1).padStart(2, '0')}-card.png`);
      await cardElements[i].screenshot({ path: imgPath, type: 'png' });
      saved.push(imgPath);
      console.log(`  ✅ ${path.basename(imgPath)}`);
    }

    return saved;
  } finally {
    await browser.close();
  }
}

// 4. 发布到小红书
async function publish(images, postData) {
  console.log('\n📤 发布到小红书...');
  console.log(`   标题: ${postData.title}`);
  console.log(`   标签: ${postData.tags.join(', ')}`);

  const client = new Client({ name: 'auto-publisher', version: '1.0.0' });
  const transport = new StreamableHTTPClientTransport(new URL(MCP_URL));
  await client.connect(transport);

  try {
    const res = await client.callTool({
      name: 'publish_content',
      arguments: {
        title: postData.title,
        content: postData.content,
        images: images,
        tags: postData.tags,
        is_original: true,
        visibility: '公开可见',
      },
    }, undefined, { timeout: 300_000 });

    console.log('\n✅ 发布成功！');
    const msg = res?.content?.[0]?.text || JSON.stringify(res, null, 2);
    console.log(msg);
  } finally {
    await client.close().catch(() => { });
  }
}

// 主流程
async function main() {
  try {
    console.log('🚀 开始自动化发布流程\n');

    // 1. 提取内容
    const data = await extractContent();

    // 2. 生成文案
    const postData = generateContent(data);

    // 3. 渲染图片
    const images = await renderCards();

    // 4. 发布
    await publish(images, postData);

    console.log('\n🎉 发布流程完成！');

  } catch (error) {
    console.error('\n❌ 发布失败:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

main();
