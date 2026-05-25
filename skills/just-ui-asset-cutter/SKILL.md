---
name: just-ui-asset-cutter
description: >
  从 AI 生成的 APP 设计图中自动识别并拆解可复用 UI 组件（按钮、图标、字体、卡片、导航等），
  输出带元数据的结构化资产清单与组件规格，可直接用于开发引用。
  支持任意设计风格，强制拆分交互层与视觉层，禁止合并导出。
---

# UI Asset Cutter — 设计图组件拆解 Skill

## 做什么

输入一张 APP UI 设计图（AI 生成或设计师导出），自动：

1. 识别画面中所有可复用 UI 组件
2. 将组件按类型分类：按钮 / 图标 / 卡片 / 导航 / 输入框 / 进度条 / 徽章 / 排版
3. 拆分交互状态（default / hover / pressed / disabled）
4. 提取每个组件的视觉规格（颜色、圆角、阴影、尺寸）
5. 输出标准化 `assets_manifest.json`（含命名、分辨率、使用场景、设计 token）
6. 生成 **`preview/index.html`**：浏览器直接打开，所有组件可见、可交互，含 hover/press/focus 状态

---

## 何时触发

强触发词：

- "帮我切图"
- "把设计图拆成组件"
- "从图里提取按钮/图标/字体"
- "生成可复用 UI 资产"
- "设计图 → 组件规格"
- "提取 UI 组件"
- "把这张设计图生成可开发的资产"
- "extract UI assets from design"
- "切图并生成 metadata"

---

## 完美输出示例

```
<project_name>/
  preview/
    index.html                    # ⭐ 浏览器打开即可预览全部组件 + 交互状态
  metadata/
    assets_manifest.json          # 完整资产清单
    design_tokens.json            # 设计 token（颜色、圆角、间距）
    component_interaction_map.md  # 状态机说明
```

> HTML 预览包含：Design Tokens 色板、Typography Scale、所有按钮/输入框/列表项/进度条
> 的 default / hover / pressed / disabled / error 各状态，直接在浏览器验收，
> 无需搭建任何开发环境。

---

## 输入

必须输入：

1. **设计图**：APP 界面截图或 AI 生成的设计图（支持 PNG / JPG / WebP）
2. **项目名称**：用于命名输出目录和资产前缀

可选输入：

1. **设计风格描述**：如"软 3D 蒙台梭利"、"扁平极简"、"Glassmorphism"
2. **输出路径**：默认 `example-output/<project_name>/`
3. **是否附带代码骨架**：默认关闭（HTML 预览为默认唯一可视输出）

---

## 输出契约

### 必须产出

1. `metadata/assets_manifest.json`：所有资产的结构化清单
2. `metadata/design_tokens.json`：主色 / 辅色 / 中性色 / 圆角 / 间距设计 token
3. `metadata/component_interaction_map.md`：每个组件的完整状态机说明
4. `preview/index.html`：**可直接在浏览器打开的组件预览页**
   - 包含 Design Tokens 色板、Typography Scale
   - 每个组件所有交互状态（hover / pressed / focused / error / disabled）
   - 使用 CSS Variables 映射设计 token，自包含，无外部依赖

### 可选产出（按需）

5. 组件代码骨架（Flutter Widget / React Native Component / SwiftUI View）

---

## 原子层切图规范（Atomic Layer Decomposition）

> **核心原则：每个 UI 元素必须按最小可复用单位拆分，禁止合并导出。**

### 按钮 = 3 层独立产物

任何按钮都必须拆成 3 个独立资产，**不允许将 background + icon + text 合并为一张图**：

| 层次 | 类型 | 产出形式 | PNG 条件 |
|------|------|---------|---------|
| **1. 背景层 (bg)** | 形状/填充 | **重建 Token JSON**（记录 fill, borderRadius, size, border） | 仅复杂渐变/图案才需 PNG |
| **2. 图标层 (icon)** | 图形 | **透明 PNG**（去背景色，保留图标像素） | 必须导出 |
| **3. 文字层 (label)** | 排版 | **文字 Token JSON**（记录 color, fontSize, fontWeight, i18n_key） | 仅艺术字/特殊字体才需 PNG |

**示例 — 微信登录按钮（绿色 pill）：**
```
btn_primary_bg.token.json    → { fill: "#52B84A", borderRadius: "9999px", width: 384, height: 73 }
icon_wechat.png              → 白色微信logo，透明底
label_wechat_login.token.json → { text: "微信登录", color: "#FFFFFF", fontSize: 17, fontWeight: "600" }
```

**示例 — 手机号登录按钮（描边 pill）：**
```
btn_outline_bg.token.json    → { fill: "transparent", border: "1.5px solid #52B84A", borderRadius: "9999px" }
icon_phone.png               → 绿色手机图标，透明底
label_phone_login.token.json → { text: "手机号登录", color: "#52B84A", fontSize: 17, fontWeight: "500" }
```

### 插图元素切图规则

| 元素类型 | 处理方式 |
|---------|---------|
| 整体场景插图 | 裁剪为 PNG（保留背景），作为装饰性资产 |
| 孤立装饰元素（植物、图标、徽章） | 裁剪 + 去背景色 → 透明 PNG |
| Logo / 品牌图标 | 裁剪 + 去背景色 → 透明 PNG |
| 角色插图（复杂背景） | 裁剪为 PNG（背景保留），标注为 `illus_*` |
| 纯文字排版 | 文字 Token（不截图），标注字体/颜色/大小 |

### 背景色去除技术

```python
def remove_bg(img, bg_color, tolerance=30):
    """通用去背景：对 tolerance 范围内的背景色像素设置 alpha=0"""
    rgba = img.convert('RGBA')
    for i, px in enumerate(rgba.getdata()):
        r,g,b,a = px
        if abs(r-bg_color[0]) + abs(g-bg_color[1]) + abs(b-bg_color[2]) < tolerance:
            rgba.putpixel((i % img.width, i // img.width), (r,g,b,0))
    return rgba

def remove_green_bg(img, tolerance=40):
    """专用于去除绿色按钮背景 (目标: 高绿低红低蓝)"""
    rgba = img.convert('RGBA')
    for i, px in enumerate(rgba.getdata()):
        r,g,b,a = px
        if g > 130 and g > r + 10 and g > b + 30:
            rgba.putpixel((i % img.width, i // img.width), (r,g,b,0))
    return rgba
```

---

## 核心约束（强制）

### 禁止导出

- ❌ 含烘焙文字的合并资产（icon + text 合并为一张图）
- ❌ 图标与按钮背景合并的截图
- ❌ 带手机 Mockup 边框的完整截图
- ❌ 阴影与背景合并（阴影必须单独描述）
- ❌ 纯色形状的 PNG（必须用 token 描述，不截图）

### 必须遵守

- ✅ 每个按钮必须拆为 bg token + icon PNG + label token（3 层原子产物）
- ✅ 图标必须透明底导出（去除背景色）
- ✅ 文字内容只记录规格 token，不栅格化
- ✅ 交互状态必须分开描述（default / pressed / disabled）
- ✅ 命名全部使用 `snake_case`
- ✅ 每个资产附 `recommended_usage` 说明

---

## 组件识别清单（覆盖范围）

### Buttons（按钮）
| 组件名 | 说明 |
|--------|------|
| `primary_button_bg` | 主 CTA 按钮背景 |
| `secondary_button_bg` | 次级按钮背景 |
| `outline_button_bg` | 描边按钮背景 |
| `icon_button_bg` | 纯图标按钮背景 |
| `tab_button_bg` | Tab 切换按钮背景 |
| `floating_action_button_bg` | 悬浮操作按钮 |

### Icons（图标）
| 组件名 | 说明 |
|--------|------|
| `home_icon` | 首页图标 |
| `back_icon` | 返回图标 |
| `close_icon` | 关闭图标 |
| `search_icon` | 搜索图标 |
| `settings_icon` | 设置图标 |
| `notification_icon` | 通知图标 |
| `profile_icon` | 用户头像占位图标 |
| `*_icon`（其余识别到的） | 按实际命名 |

### Cards（卡片）
| 组件名 | 说明 |
|--------|------|
| `content_card_bg` | 内容卡片背景 |
| `profile_card_bg` | 个人信息卡片 |
| `modal_card_bg` | 弹窗卡片 |
| `floating_card_bg` | 悬浮卡片 |

### Navigation（导航）
| 组件名 | 说明 |
|--------|------|
| `top_nav_bg` | 顶部导航栏背景 |
| `bottom_tab_bg` | 底部 Tab 栏背景 |
| `segmented_control_bg` | 分段选择器背景 |

### Inputs（输入框）
| 组件名 | 说明 |
|--------|------|
| `input_field_bg` | 文本输入框背景 |
| `search_field_bg` | 搜索框背景 |
| `dropdown_bg` | 下拉选择框背景 |

### Progress（进度）
| 组件名 | 说明 |
|--------|------|
| `progress_track_bg` | 进度条轨道背景 |
| `progress_fill` | 进度填充 |
| `level_badge_bg` | 等级徽章背景 |

### Badges & Rewards（徽章与奖励）
| 组件名 | 说明 |
|--------|------|
| `badge_*` | 任意徽章，按识别内容命名 |
| `reward_*` | 奖励资产，按识别内容命名 |

---

## 分辨率规则

| 类型 | 导出尺寸 |
|------|---------|
| 小图标（icon） | 512 × 512 |
| 按钮背景（button） | 1024 × 512 |
| 卡片背景（card） | 1280 × 720 |
| 徽章（badge） | 1024 × 1024 |
| 通用大资产 | 2048 × 2048 |

所有资产保留 **8–16px 安全透明边距**（safe padding）。

---

## assets_manifest.json 结构

```json
[
  {
    "asset_name": "primary_button_bg",
    "category": "buttons",
    "file_path": "assets/ui_kit/buttons/primary_button_bg.png",
    "export_resolution": "1024x512",
    "transparent_background": true,
    "recommended_usage": "主要操作按钮，CTA 场景",
    "interaction_states": ["default", "pressed", "disabled"],
    "visual_spec": {
      "primary_color": "#5EC16A",
      "secondary_color": "#4AAD56",
      "corner_radius": "24px",
      "shadow_style": "soft drop shadow, 4px blur, 20% opacity",
      "material": "solid with gradient overlay",
      "lighting": "top-left soft highlight"
    }
  }
]
```

---

## design_tokens.json 结构

```json
{
  "colors": {
    "primary": "#5EC16A",
    "primary_dark": "#4AAD56",
    "secondary": "#FF9F3F",
    "background": "#FDF8F0",
    "surface": "#FFFFFF",
    "text_primary": "#2D2D2D",
    "text_secondary": "#8A8A8A",
    "error": "#FF4B4B"
  },
  "radii": {
    "small": "8px",
    "medium": "16px",
    "large": "24px",
    "pill": "9999px"
  },
  "spacing": {
    "xs": "4px",
    "sm": "8px",
    "md": "16px",
    "lg": "24px",
    "xl": "32px"
  },
  "typography": {
    "font_primary": "Nunito",
    "font_secondary": "Fredoka",
    "font_cjk": "HarmonyOS Sans SC",
    "sizes": {
      "h1": "32px",
      "h2": "24px",
      "body": "16px",
      "caption": "12px"
    },
    "weights": {
      "regular": 400,
      "medium": 500,
      "bold": 700,
      "extra_bold": 800
    }
  },
  "shadows": {
    "card": "0 4px 16px rgba(0,0,0,0.10)",
    "button": "0 2px 8px rgba(0,0,0,0.15)",
    "float": "0 8px 32px rgba(0,0,0,0.12)"
  }
}
```

---

## typography_spec.md 结构

```markdown
# Typography Specification

## 标题 H1
- Font: Nunito / HarmonyOS Sans SC
- Size: 32px
- Weight: ExtraBold (800)
- Color: #2D2D2D
- Line Height: 40px

## 正文 Body
- Font: Nunito / HarmonyOS Sans SC
- Size: 16px
- Weight: Regular (400)
- Color: #2D2D2D
- Line Height: 24px

## 按钮文字
- Font: Nunito / HarmonyOS Sans SC
- Size: 18px
- Weight: Bold (700)
- Color: #FFFFFF（在深色按钮上）
- Letter Spacing: 0.5px
```

---

## 代码骨架（可选，按需生成）

### Flutter 按钮骨架示例

```dart
// primary_button.dart
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isDisabled;

  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey : Color(0xFF5EC16A),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 执行流程（Workflow）

```
Step 1: 图像分析
  → 扫描设计图，列出所有可识别组件
  → 按类型分组（按钮 / 图标 / 卡片 / 导航 / 输入 / 进度 / 徽章）
  → 标注每个组件的像素位置区域

Step 2: 视觉规格提取
  → 逐组件提取：颜色 / 圆角 / 阴影 / 尺寸
  → 识别交互状态（default / pressed / disabled）
  → 提取设计 token（主色 / 辅色 / 间距 / 字体）
  [CHECKPOINT] 输出组件识别列表，等待确认是否遗漏

Step 3: 规格产出
  → 生成 assets_manifest.json
  → 生成 design_tokens.json
  → 生成 typography_spec.md
  → （可选）生成 component_interaction_map.md

Step 4: 代码骨架（按需）
  → 根据目标平台生成每个组件的代码骨架
  → 骨架使用 design_tokens 中的值，不硬编码

Step 5: 输出收口
  → 按 /assets/ui_kit/ 目录结构整理所有产物
  → 输出完整资产清单摘要
```

---

## Checkpoint 规则

| 节点 | 停止条件 | 恢复条件 |
|------|---------|---------|
| Step 2 完成后 | 输出组件识别清单，等用户确认 | 用户确认或补充遗漏 |
| Step 4 前 | 询问是否需要代码骨架及目标平台 | 用户回答 |

---

## Three-Question Design Test

### Q1: What exact job does this skill perform?
Automatically identify and decompose reusable UI components from AI-generated app design images. Extract atomic layers (button bg/icon/label as separate assets), generate structured metadata with design tokens, output interactive HTML preview with all component states (default/hover/pressed/disabled), and optionally generate code skeletons.

### Q2: When should it activate? List at least 5 trigger phrases.
1. "cut assets from this design" or "slice this UI"
2. "decompose design into components" or "extract UI components"
3. "generate reusable UI assets from image"
4. "design to component specs" or "extract buttons/icons/fonts"
5. "cut this design and generate metadata"

### Q3: What does perfect output look like? Include one concrete output example.
Perfect output includes: structured assets_manifest.json with all components categorized, design_tokens.json with colors/radii/spacing/typography, component_interaction_map.md with state machines, and preview/index.html showing all components with interactive states in browser (no dev environment needed).

Example:
```
✅ UI Asset Extraction Complete: MyApp Login Screen

Output:
- metadata/assets_manifest.json (24 components)
  - 6 buttons (primary/secondary/outline, each with 3 states)
  - 8 icons (transparent PNG, 512×512)
  - 4 cards (background specs)
  - 6 input fields (with error states)

- metadata/design_tokens.json
  - Colors: primary #5EC16A, secondary #FF9F3F, 8 neutrals
  - Radii: small 8px, medium 16px, large 24px, pill 9999px
  - Typography: Nunito/HarmonyOS Sans, 4 sizes, 3 weights

- preview/index.html
  - Design tokens color palette ✓
  - Typography scale ✓
  - All buttons with hover/pressed/disabled states ✓
  - All inputs with default/focus/error states ✓
  - Interactive preview, no dependencies ✓

Atomic decomposition: 3-layer separation enforced (bg token + icon PNG + label token)
```

## 边界与非目标

### 在范围内

- 从设计图中识别和描述 UI 组件规格
- 生成资产元数据与设计 token
- 生成组件代码骨架（骨架，不含业务逻辑）
- 提取排版规格（不栅格化文字）

### 不在范围内

- ❌ 构建完整的设计系统文档
- ❌ 生成业务逻辑代码
- ❌ 替代设计师的主观决策
- ❌ 自动上传或发布资产到任何平台
- ❌ 对复杂混合背景插图进行完美抠图（需人工 Figma 操作）
