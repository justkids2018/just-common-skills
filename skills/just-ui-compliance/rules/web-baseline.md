# Web Visual Baseline (Default)

> 只管"看不看得见"和"舒不舒服"，不管颜色。

## Typography

| 层级 | 字号 | 行高比 | 典型用途 |
|------|------|--------|---------|
| H1 | 36–48 px | 1.15–1.25 | 页面主标题 |
| H2 | 26–32 px | 1.2–1.3 | 区块标题 |
| H3 | 20–24 px | 1.25–1.35 | 卡片/列表标题 |
| Body | 16–19 px | 1.45–1.65 | 正文 |
| Secondary | 14–16 px | 1.35–1.5 | 副文本、说明 |
| Caption / Hint | 12–14 px | 1.2–1.4 | 表单提示、图片说明 |
| 绝对最小 | 11 px | — | 仅装饰性极细字 |

### 违规判定
- 非装饰性文字 `< 11 px` → **BLOCKER**
- Caption 类文字 `< 12 px` → **HIGH**

## Button Layout Formula（同移动端核心逻辑）

```
button_height >= font_size_px × 1.4 + vertical_padding_top + vertical_padding_bottom
```

| 按钮规格 | 字号（推荐） | 上下 padding（各） | 最小按钮高度 |
|---------|------------|-----------------|------------|
| 标准主按钮 | 15–17 px | 10–14 px | 44–52 px |
| 大号按钮 | 17–19 px | 14–18 px | 52–62 px |
| 小号/Chip | 13–15 px | 6–10 px | 30–40 px |

- 按钮文字被裁切 → **BLOCKER**
- 按钮宽度不足导致文字换行或截断 → **HIGH**

## Controls and Spacing

- Minimum interactive target: 44 × 44 px（触摸优先页面）
- Input height: ≥ 44 px
- Spacing grid: 8 px
- Horizontal page margin: 16–24 px（窄屏）；24–48 px（宽屏）

## Corner Radius

| 组件 | 圆角 |
|------|------|
| 标准按钮 | 8–12 px |
| 输入框 | 6–10 px |
| 卡片 | 10–16 px |
| Pill/胶囊 | ≥ 20 px |

## Text Overflow and Clipping

- 任何容器固定高度 + overflow:hidden → 必须有 ellipsis 或 line-clamp
- 末行文字只露出 1–4 px → **HIGH**
- 文字完全消失（容器高度不足）→ **BLOCKER**
- 最大可读行宽：正文约 65–75 ch，过宽会导致行末文字视觉断裂

## Breakpoint Integrity

- 在以下断点验证内容不溢出、不重叠：
  - 375 px（小手机）
  - 768 px（平板）
  - 1024 px（小笔记本）
  - 1440 px（标准桌面）
- 任意断点出现文字被遮挡或溢出 → **HIGH**

## Zoom Compatibility

- 在 125% 和 150% 缩放下验证：
  - 按钮文字是否仍完整显示
  - 卡片末行是否被截断
  - 125% 下按钮文字被截 → **BLOCKER**
