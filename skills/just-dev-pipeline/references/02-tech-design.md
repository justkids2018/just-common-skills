# 技术设计模板

> 复制本模板填写到 `doc/features/<feature-name>/03-design.md`

---

## 关联需求

- 需求文档：[01-requirement.md](01-requirement.md)
- 需求 ID 覆盖：R-1, R-2, ...

## 整体方案

<2-3 句话说清楚怎么做>

## 架构定位

> **必须显式说明**本设计如何符合 [`baseline/02-architecture.md`](../baseline/02-architecture.md)

- **本功能涉及哪几层**：Entity / UseCase / Adapter / Framework
- **依赖方向**：<画清楚>
- **是否引入新模块**：是 / 否，理由：

## 数据模型

### 新增 / 修改的实体

```rust
// 示例
pub struct Favorite {
    pub id: Uuid,
    pub user_id: Uuid,
    pub company_id: Uuid,
    pub created_at: DateTime<Utc>,
}
```

### 数据库变更

- 迁移文件：`database/migrations/NNN_xxx.sql`
- DDL：
  ```sql
  CREATE TABLE ...
  ```
- 索引：
- 回滚方案：

## 接口设计

### 后端 API

| Method | Path | 用途 | 认证 |
|--------|------|------|------|
| POST | `/api/favorites` | 添加收藏 | 是 |
| ... | ... | ... | ... |

### 请求 / 响应示例

```json
// POST /api/favorites
{ "company_id": "..." }

// 200
{ "id": "...", "company_id": "...", "created_at": "..." }
```

### 前端契约

- Service 函数：`addFavorite(companyId)`
- Store 字段：`favorites: Favorite[]`
- 影响组件：

## 数据流

```
用户点击 → Component → Store → Service → API → Controller → UseCase → Repo → DB
                                          ↓
                                       响应回流
```

## 关键设计决策

> 每个决策必须能回答："为什么不用更简单的方式？"

- **决策 1**：<选择 X 而不是 Y>
  - 理由：
  - 备选方案：
- **决策 2**：...

## 依赖

- 新增依赖（npm / cargo）：
- 影响的已有模块：
- 外部服务：

## 风险与缓解

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| ... | 高/中/低 | 高/中/低 | ... |

## 性能 / 安全考量

- **性能**：预估 QPS、SQL 索引、缓存策略
- **安全**：输入校验位置、权限检查、SQL 注入防护

## 不做什么（设计层面）

- ❌ 不引入新框架
- ❌ 不重构现有模块

## 验证方式

- 编译：`cargo build`
- 测试：`cargo test xxx`
- 手测：访问 ___，看 ___

---

**Gate 检查**：

- [ ] 显式引用了 baseline 架构规则
- [ ] 关键决策给出了"为什么"
- [ ] 数据迁移有回滚方案
- [ ] 风险有缓解措施
