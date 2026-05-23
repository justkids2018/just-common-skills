---
name: just-investigate
description: 根因分析技能。用于在失败、回归或异常时定位真正原因并给出修复路径。
---

# just-investigate

## Purpose

先定位根因，再制定修复方案，避免盲目改动。

## Inputs

- 错误日志或异常现象
- 相关变更记录
- 复现步骤

## Outputs

- 根因结论
- 证据链
- 修复建议与验证方案
- `DIAGNOSIS.md`（结构化修复计划）

## Steps

1. 复现问题并收集最小证据集。
2. 排除非根因干扰项，定位直接根因。
3. 产出修复建议并定义验证路径。
4. 以统一格式写入或更新 `DIAGNOSIS.md`。

## DIAGNOSIS 模板（建议）

```md
## Failure Signature
<ExceptionType: message or failure title>

## Root Cause
<2-4 sentences>

## Evidence
- <log/file/command evidence 1>
- <evidence 2>

## Affected Scope
- <file/module/feature>

## Patch Plan
1. <imperative fix step>
2. <imperative fix step>

## Regression Risk
<one-liner>

## Verification Plan
1. <build/test command>
2. <manual verification points>
```

## Constraints

- 未定位根因前，不进入大规模修复。
- 结论必须有可复现证据支撑。
- 若无法复现，必须明确缺失条件。
- 存在失败时，`DIAGNOSIS.md` 为必需产物。
