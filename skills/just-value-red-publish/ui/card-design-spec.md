# 小红书卡片设计规范

> 模板位置：`templates/card-template-standard.html`  
> 样式文件：`templates/card-styles.css`  
> 品牌色映射：`ui/brand-colors.md`

---

## 基础规格

| 项目 | 规格 |
|------|------|
| 基准尺寸 | 370 × 550px |
| 缩放策略 | 按视口自动等比缩放（移动端自适应） |
| 导出分辨率 | html2canvas，scale: 2（高清 2x） |
| 字体 | 系统默认中文字体栈 |

---

## 封面卡（c1）设计

### 布局层次
1. 全幅背景图（公司 Logo/实拍图，自动裁切）
2. 渐变遮罩（左深右浅，兼顾图片突出与文案可读）
3. 文案层（标题 + 副标题 + hero-item）
4. Just 60 徽章（右上角）

### 封面图优先级
`cover.jpg` > `cover.jpeg` > `cover.png` > `hero.jpg` > `hero.jpeg` > `logo.png` > `icon.png` > `main.png`  
无图片时：使用品牌色纯色渐变背景（见 `ui/brand-colors.md`）

### 文字规格
- 标题：28px，颜色 `#f8fafc`
- 副标题：14px，建议 8-16 字，优先一句主结论
- hero-text：13px

### hero-item 样式（毛玻璃卡片）
```css
background: rgba(10, 20, 35, 0.22);
backdrop-filter: blur(20px);
border: 1.5px solid rgba(255, 255, 255, 0.16);
```

### 封面内边距
```css
padding: 72px 28px 30px 28px;
```

---

## 内容卡设计

### 卡片背景（统一深灰渐变）
```css
background: linear-gradient(135deg, #1f2937 0%, #111827 100%);
```

### 数据卡片 / 堆叠卡片样式
```css
background: rgba(255, 255, 255, 0.12);
border: 1.5px solid rgba(255, 255, 255, 0.2);
backdrop-filter: blur(20px);
box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
```

### 编号徽章（32×32px，圆角 8px）
颜色定义见 `ui/brand-colors.md §编号徽章渐变色`

---

## Just 60 徽章（每张卡片右上角）
```css
background: rgba(100, 100, 100, 0.35);
backdrop-filter: blur(20px);
border: 1.5px solid rgba(255, 255, 255, 0.2);
```

---

## 卡片内容结构

### 财报分析（7张）

| 编号 | 内容 | 组件类型 |
|------|------|---------|
| c1 | 封面：公司名 + 季度 + 3个 hero-item 核心数字 | cover |
| c2 | 核心数据（4个核心指标） | metric-grid 2×2 |
| c3 | 业务亮点 | stack-item 堆叠 |
| c4 | 战略分析 | stack-item 堆叠 |
| c5 | 宏观四维评级（区域本土优先/反脆弱性/消费分层/AI冲击） | rating-grid 2×2 |
| c6 | 最大风险 | stack-item 堆叠 |
| c7 | 估值分析 | data-table + stack-item |

### 行业 / 商业分析（6-7张）

| 编号 | 内容 | 组件类型 |
|------|------|---------|
| c1 | 封面：公司名 + 主题 + 3个 hero-item | cover |
| c2 | 市场规模 / 核心数据 | metric-grid |
| c3 | 竞争格局 | data-table + stack-item |
| c4 | 行业趋势 / 商业飞轮 | stack-item 堆叠 |
| c5 | 宏观四维评级 | rating-grid 2×2 |
| c6 | 核心洞察 / 多空论点 | stack-item 堆叠 |
| c7 | 免责声明（可选） | plain |

---

## 一键下载功能

```javascript
// html2canvas 导出 PNG
html2canvas(cardElement, { scale: 2 }).then(canvas => {
  const link = document.createElement('a');
  link.download = `${companyName}-${cardId}.png`;
  link.href = canvas.toDataURL('image/png');
  link.click();
});
```
