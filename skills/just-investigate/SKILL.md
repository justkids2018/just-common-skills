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

## Three-Question Design Test

### Q1: What exact job does this skill perform?
Perform root cause analysis for failures, regressions, or anomalies. Reproduce the issue, collect minimal evidence, eliminate non-root-cause distractors, identify the direct cause, and output structured diagnosis with fix recommendations in `DIAGNOSIS.md`.

### Q2: When should it activate? List at least 5 trigger phrases.
1. "investigate this failure" or "find the root cause"
2. "why did this break?" or "diagnose this error"
3. "analyze this regression" or "what went wrong?"
4. "debug this issue" or "trace this problem"
5. "root cause analysis needed" or "investigate before fixing"

### Q3: What does perfect output look like? Include one concrete output example.
Perfect output includes: clear root cause statement, evidence chain with logs/files/commands, affected scope, step-by-step patch plan, regression risk assessment, and verification plan in structured `DIAGNOSIS.md`.

Example:
```
## DIAGNOSIS.md

### Failure Signature
NullPointerException: Cannot read property 'email' of null at UserService.java:45

### Root Cause
User object returned null when session token expired. Auth middleware failed to refresh token before passing request to UserService.

### Evidence
- Log: auth.log line 234 "Token expired: abc123"
- Code: auth_middleware.dart:67 missing token refresh call
- Repro: Login → wait 31 min → access profile

### Affected Scope
- auth_middleware.dart
- user_service.java
- All authenticated endpoints

### Patch Plan
1. Add token refresh check in auth_middleware.dart before request forwarding
2. Add unit test for expired token scenario
3. Add integration test for 30min+ session

### Regression Risk
Low - isolated to auth flow, existing tests cover happy path

### Verification Plan
1. Run: `flutter test test/auth/`
2. Manual: Login → wait 31min → verify profile loads
```

## Constraints

- 未定位根因前，不进入大规模修复。
- 结论必须有可复现证据支撑。
- 若无法复现，必须明确缺失条件。
- 存在失败时，`DIAGNOSIS.md` 为必需产物。
