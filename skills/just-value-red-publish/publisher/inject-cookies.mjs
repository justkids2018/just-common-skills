/**
 * 将 cookies.json 注入到 MCP 正在运行的 Chromium 浏览器中
 * 关键：全程使用同一个 MCP 连接，确保 MCP 复用同一个浏览器实例
 * 用法: node inject-cookies.mjs
 */
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StreamableHTTPClientTransport } from '@modelcontextprotocol/sdk/client/streamableHttp.js';
import puppeteer from 'puppeteer';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const MCP_URL = 'http://localhost:18060/mcp';
const ROD_USER_DATA = '/var/folders/16/kvts2d953_j9w75ygjwxc8zh0000gn/T/rod/user-data';

const cookies = JSON.parse(fs.readFileSync(path.join(__dirname, 'cookies.json'), 'utf-8'));

// 1. 建立单个 MCP 连接（全程不关闭，保证浏览器实例复用）
console.log('🔧 触发 MCP 启动浏览器...');
const mcpClient = new Client({ name: 'inject', version: '1.0.0' });
const transport = new StreamableHTTPClientTransport(new URL(MCP_URL));
await mcpClient.connect(transport);

// 非阻塞调用 get_login_qrcode，触发浏览器启动（不 await，保持连接活跃）
mcpClient.callTool({ name: 'get_login_qrcode', arguments: {} }, undefined, { timeout: 180_000 }).catch(() => { });

// 等浏览器启动
await new Promise(r => setTimeout(r, 4000));

// 2. 找到 DevToolsActivePort（按最新修改时间排序）
let cdpPort = null;
let userDataDir = null;
if (fs.existsSync(ROD_USER_DATA)) {
    const rodDirs = fs.readdirSync(ROD_USER_DATA)
        .map(dir => ({ dir, mtime: fs.statSync(path.join(ROD_USER_DATA, dir)).mtimeMs }))
        .sort((a, b) => b.mtime - a.mtime);

    for (const { dir } of rodDirs) {
        const portFile = path.join(ROD_USER_DATA, dir, 'DevToolsActivePort');
        if (fs.existsSync(portFile)) {
            const port = fs.readFileSync(portFile, 'utf-8').split('\n')[0].trim();
            if (port && parseInt(port) > 0) {
                cdpPort = port;
                userDataDir = dir;
                break;
            }
        }
    }
}

if (!cdpPort) {
    console.error('❌ 找不到 Chromium DevTools 端口，浏览器未启动');
    await mcpClient.close().catch(() => { });
    process.exit(1);
}

console.log(`✅ 找到浏览器 port=${cdpPort} dir=${userDataDir}`);

// 3. 注入 cookies（只保留 CDP 支持的字段）
const browser = await puppeteer.connect({
    browserURL: `http://localhost:${cdpPort}`,
    defaultViewport: null,
});

const pages = await browser.pages();
const page = pages[0] || await browser.newPage();

const importable = cookies
    .filter(c => c.name && c.value && (c.expires > 0 || c.name === 'web_session'))
    .map(({ name, value, domain, path: cookiePath, expires, httpOnly, secure }) => ({
        name, value, domain,
        path: cookiePath || '/',
        ...(expires > 0 ? { expires } : {}),
        httpOnly: !!httpOnly,
        secure: !!secure,
    }));

await page.setCookie(...importable);
console.log(`✅ 注入 ${importable.length} 个 cookies`);

// 加载小红书让浏览器激活 session
await page.goto('https://www.xiaohongshu.com', { waitUntil: 'domcontentloaded', timeout: 15000 });
console.log(`📄 页面: ${await page.title()}`);
await browser.disconnect();

// 4. 用同一个 MCP 连接验证登录（MCP 复用同一浏览器实例）
console.log('\n🔍 验证 MCP 登录状态（同一 MCP 连接）...');
await new Promise(r => setTimeout(r, 1000));
const res = await mcpClient.callTool({ name: 'check_login_status', arguments: {} }, undefined, { timeout: 30000 });
console.log(res?.content?.[0]?.text ?? JSON.stringify(res));

await mcpClient.close().catch(() => { });
