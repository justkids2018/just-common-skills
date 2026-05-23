# start-local-services

## Purpose

启动 Hi Kiki 本地开发环境（PostgreSQL + Rust 后端 + Vue 前端）

## Inputs

无需输入参数

## Outputs

- 服务启动状态
- 访问地址和端口信息
- 日志文件路径

## Steps

1. 执行启动脚本 `scripts/local_dev/start.sh`
2. 检测各服务状态（PostgreSQL、Rust 后端、Vue 前端）
3. 如果服务已运行，跳过启动
4. 如果服务未运行，自动启动
5. 显示最终状态和访问信息

## Constraints

- 自动检测服务是否已启动，避免重复启动
- 启动失败时显示日志路径
- 所有服务在后台运行，不阻塞终端

## Triggers

当用户说以下内容时自动触发：
- "启动本地服务"
- "启动本地环境"
- "start local"
- "启动开发环境"
- "启动后端"
- "启动前端"
- "启动数据库"
