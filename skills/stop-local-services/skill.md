# stop-local-services

## Purpose

停止 Hi Kiki 本地开发环境（Rust 后端 + Vue 前端，可选停止 PostgreSQL）

## Inputs

无需输入参数

## Outputs

- 服务停止状态
- 是否停止数据库的确认

## Steps

1. 执行停止脚本 `scripts/local_dev/stop.sh`
2. 停止 Rust 后端服务
3. 停止 Vue 前端服务
4. 询问是否停止 PostgreSQL（默认保持运行）

## Constraints

- 通过 PID 文件或端口查找进程
- 优雅停止，不使用 kill -9
- 数据库默认保持运行（避免数据丢失）

## Triggers

当用户说以下内容时自动触发：
- "停止本地服务"
- "停止本地环境"
- "stop local"
- "停止开发环境"
- "关闭后端"
- "关闭前端"
