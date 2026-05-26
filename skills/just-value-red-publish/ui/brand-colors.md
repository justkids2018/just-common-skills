# 品牌色映射表

> 生成 HTML 时，根据公司名称匹配品牌色，设置封面 `.cover-bg` 的内联样式。  
> CSS token 定义在本文件末尾。

---

## 公司品牌色对照

| 公司 | 品牌色渐变 | 说明 |
|------|-----------|------|
| 腾讯 | `#4a9eff → #2563eb` | 蓝色（微信/QQ） |
| 阿里巴巴 | `#FF6B35 → #d4a574` | 橙色 |
| 字节跳动 | `#1f2937 → #0ea5e9` | 黑蓝色 |
| 拼多多 | `#FF6B35 → #f97316` | 橙红色 |
| 美团 | `#FFD100 → #FFA500` | 黄橙色 |
| 京东 | `#E3393C → #C81623` | 红色 |
| 小米 | `#FF6700 → #FF8533` | 橙色 |
| 华为 | `#C8102E → #E60012` | 红色 |
| 比亚迪 | `#0066CC → #0080FF` | 蓝色 |
| 宁德时代 | `#00A0E9 → #0080C8` | 蓝色 |
| 茅台 | `#C8102E → #8B0000` | 深红色 |
| 爱马仕 | `#FF6B35 → #d4a574` | 橙金色 |
| LVMH | `#1f2937 → #8B4513` | 深棕色 |
| Robinhood | `#00C805 → #007a03` | 绿色 |
| Apple | `#1d1d1f → #424245` | 深灰色 |
| Microsoft | `#0078d4 → #005a9e` | 蓝色 |
| Google | `#4285F4 → #2c5fc5` | 蓝色 |
| Meta | `#0866FF → #1877F2` | 蓝色 |
| Amazon | `#FF9900 → #e47911` | 橙色 |
| NVIDIA | `#76b900 → #5a8c00` | 绿色 |
| Tesla | `#CC0000 → #991a1a` | 红色 |
| Circle | `#1652F0 → #0d3dbf` | 蓝色 |
| **默认** | `#4a9eff → #2563eb` | 蓝色 |

---

## CSS Token 定义

```css
:root {
  /* 内容卡背景 */
  --content-bg: linear-gradient(135deg, #1f2937 0%, #111827 100%);

  /* 文字层级 */
  --text-main:  #f9fafb;
  --text-sub:   rgba(249, 250, 251, 0.74);
  --text-muted: rgba(249, 250, 251, 0.58);

  /* 强调色 */
  --accent-blue:   #60a5fa;
  --accent-green:  #34d399;
  --accent-gold:   #fbbf24;
  --accent-red:    #f87171;
  --accent-purple: #a78bfa;
}
```

---

## 编号徽章渐变色

```css
/* blue */  background: linear-gradient(135deg, #4b7bff 0%, #78a3ff 100%);
/* gold */  background: linear-gradient(135deg, #d88919 0%, #f2bc59 100%);
/* green */ background: linear-gradient(135deg, #1ea672 0%, #57cf9d 100%);
/* purple */background: linear-gradient(135deg, #e0456a 0%, #f4879d 100%);
```
