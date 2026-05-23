# 标准卡片模板系统 - 完成总结

**完成时间**：2026-05-18
**目标**：建立统一的、可复用的小红书卡片标准模板系统

---

## ✅ 已完成的工作

### 1. 创建标准模板库

**位置**：`.claude/templates/`

```
.claude/templates/
├── card-template-standard.html    # 标准 HTML 模板（通用结构）
├── card-styles.css                # 独立 CSS 样式（爱马仕风格）
└── README.md                      # 完整使用说明文档
```

### 2. 设计规范标准化

**核心特点**：
- ✅ 370×550px 固定尺寸，直角设计
- ✅ 专业深色系配色（深灰渐变 + 毛玻璃效果）
- ✅ 动态品牌色支持（14个常见公司 + 默认色）
- ✅ 封面 Logo/Icon 自动检测加载
- ✅ Just 60 徽章毛玻璃效果
- ✅ 点状编号徽章（4种渐变色）
- ✅ 一键下载功能（html2canvas，2x 高清）

### 3. 品牌色映射表

已添加到 `research.md`，支持以下公司：
- 腾讯、阿里巴巴、字节跳动、拼多多
- 美团、京东、小米、华为
- 比亚迪、宁德时代、茅台
- 爱马仕、LVMH
- 默认蓝色（未匹配公司）

### 4. 更新 research skill

**更新内容**：
- ✅ Phase 4 添加品牌色映射表
- ✅ 4.2 小红书卡片部分完全重写
- ✅ 引用标准模板路径（`.claude/templates/`）
- ✅ 详细的设计规范说明
- ✅ 封面 Logo/Icon 使用说明
- ✅ 卡片结构模板（财报 7张 / 行业 6-7张）

---

## 🎯 核心优势

### 单一真相来源
- 所有 skills 引用同一个标准模板
- 样式更新只需改一个地方
- 避免不同项目样式不一致

### 稳定可靠
- 不做复杂的自动识别
- 用户手动准备 Logo（可选）
- 模板通用，适用任何公司/行业

### 易于维护
- HTML、CSS、文档分离
- 版本控制清晰
- 可移植到其他项目

### 专业视觉
- 基于爱马仕系列成功经验
- 毛玻璃效果 + 深色系
- 品牌色动态适配

---

## 📖 使用流程

### 自动化流程（通过 research skill）

```bash
/just-value-red-publish 腾讯 Q1财报
```

**自动执行**：
1. skill 识别公司名 = "腾讯"
2. 查询品牌色映射表 → 蓝色渐变 `#4a9eff → #2563eb`
3. 读取标准模板（`.claude/templates/card-template-standard.html`）
4. 读取标准样式（`.claude/templates/card-styles.css`）
5. 填充分析数据
6. 生成完整 HTML 到目标目录
7. 提示用户：可选放置 Logo 到同目录

### 手动流程（直接使用模板）

```bash
# 1. 复制模板到目标目录
cp .claude/templates/card-template-standard.html ./目标目录/cards.html
cp .claude/templates/card-styles.css ./目标目录/card-styles.css

# 2. 编辑 cards.html
# - 修改封面品牌色（内联样式）
# - 填充实际数据

# 3. 可选：放置公司 Logo
cp ./logo.png ./目标目录/logo.png

# 4. 在浏览器中打开 cards.html
# 5. 点击"一键下载全部卡片"
```

---

## 🎨 封面 Logo 使用

### 准备图片
1. **格式**：PNG（推荐透明背景）
2. **尺寸**：512×512px 或更大
3. **命名**：`logo.png` / `icon.png` / `cover.png` / `main.png`
4. **位置**：与 HTML 文件同目录

### 自动加载
模板会自动尝试加载以上文件名，找到任何一个就显示在封面右下角。

### 不使用图片
如果不需要，什么都不用做。纯色渐变背景也很专业。

---

## 📦 卡片结构

### 财报分析（7张）
1. 封面：公司名 + 季度 + 3个核心数据
2. 核心数据：2×2 metric-grid
3. 业务亮点：stack-item 堆叠
4. 战略分析：stack-item 堆叠
5. 宏观四维评级：2×2 rating-grid
6. 最大风险：stack-item 堆叠
7. 估值分析：data-table + stack-item

### 行业/商业分析（6-7张）
1. 封面：公司名 + 主题 + 3个洞察
2. 市场规模：metric-grid
3. 竞争格局：data-table + stack-item
4. 行业趋势：stack-item 堆叠
5. 宏观四维评级：rating-grid
6. 核心洞察：stack-item 堆叠
7. 免责声明（可选）

---

## 🔄 未来扩展

### 添加新公司品牌色
编辑 `research.md` 的品牌色映射表：
```markdown
| 新公司 | `#起始色 → #结束色` | 说明 |
```

### 更新样式
编辑 `.claude/templates/card-styles.css`，所有使用该模板的项目自动应用新样式。

### 添加新卡片类型
在 `card-template-standard.html` 中添加新的卡片结构，更新 `README.md` 说明。

---

## 📁 文件清单

### 新增文件
- `.claude/templates/card-template-standard.html` - 标准 HTML 模板
- `.claude/templates/card-styles.css` - 独立 CSS 样式
- `.claude/templates/README.md` - 使用说明文档
- `.claude/templates/SUMMARY.md` - 本总结文档

### 更新文件
- `.claude/skills/just-value-red-publish/skill.md` - 添加品牌色映射表和模板引用

### 示例文件
- `Just学投资/腾讯研究/腾讯-Q1-2026-cards.html` - 基于新模板生成的示例

---

## ✨ 成果展示

**腾讯 Q1 2026 财报卡片**：
- 位置：`Just学投资/腾讯研究/腾讯-Q1-2026-cards.html`
- 特点：
  - 蓝色品牌色渐变（腾讯）
  - 7张卡片完整结构
  - 专业深色系 + 毛玻璃效果
  - 一键下载功能

---

## 🎓 最佳实践

1. **保持模板稳定**：不要频繁修改核心结构
2. **品牌色适配**：为常见公司添加品牌色映射
3. **Logo 可选**：不强制要求，纯色也好看
4. **内容密度**：每张卡片 2-4 个信息点
5. **留白舒适**：不要塞满，保持呼吸感

---

**系统状态**：✅ 已完成，可投入使用
**下次使用**：执行 `/just-value-red-publish [公司] [类型]` 即可自动应用新模板
