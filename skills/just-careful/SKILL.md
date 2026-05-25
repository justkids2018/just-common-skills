---
name: just-careful
description: 危险操作防护技能。用于在破坏性命令执行前进行确认、范围限制与回滚预案检查。
---

# just-careful

## Purpose

在高风险操作前增加安全闸门，避免误删、误推送与不可逆损失。

## Inputs

- 即将执行的命令
- 影响范围
- 回滚方案

## Outputs

- 风险等级判断
- 执行前确认结果
- 回滚准备状态

## Steps

1. 识别命令风险级别与影响对象。
2. 要求显式确认并复述影响范围。
3. 检查回滚方案后再允许执行。

## Three-Question Design Test

### Q1: What exact job does this skill perform?
Add safety gates before high-risk operations. Identify command risk level, require explicit confirmation with impact scope recitation, verify rollback plan exists, and only then allow execution of destructive commands.

### Q2: When should it activate? List at least 5 trigger phrases.
1. Before any `rm -rf`, `DROP TABLE`, or `git reset --hard`
2. Before `git push --force` or `git push -f`
3. Before database migrations with `down` or volume removal
4. Before deleting branches, files, or production resources
5. Before any operation marked as "destructive" or "irreversible"

### Q3: What does perfect output look like? Include one concrete output example.
Perfect output includes: risk level assessment (HIGH/MEDIUM/LOW), clear impact scope statement, rollback plan verification, explicit user confirmation prompt, and execution only after approval.

Example:
```
⚠️  CAREFUL CHECK: HIGH RISK OPERATION

Command: git push --force origin main
Risk Level: HIGH
Impact Scope:
- Will overwrite remote main branch history
- Affects all team members pulling from main
- 3 commits will be lost: abc123, def456, ghi789

Rollback Plan:
- Remote backup exists at origin/main-backup-20260115
- Can restore with: git push origin main-backup-20260115:main

❌ BLOCKED: Explicit confirmation required.
Type "I understand the risks and approve force push to main" to proceed.
```

## Constraints

- 未确认不得执行破坏性命令。
- 未提供回滚方案不得继续高风险操作。
- 不得绕过确认流程。
