#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/deploy-release/bin/common.sh
source "$SCRIPT_DIR/bin/common.sh"

PROFILE_NAME="${1:-}"
load_profile "$PROFILE_NAME"

print_header "DB 发布流程 (${DEPLOY_PROVIDER})"

if [[ "${SKIP_DB_MIGRATION:-}" == "true" ]]; then
  echo -e "${YELLOW}⚠️ SKIP_DB_MIGRATION=true，跳过数据库迁移${NC}"; exit 0
fi

ensure_ssh

echo -e "${YELLOW}1) 启动数据库容器...${NC}"
remote_compose "up -d postgres"

for _ in {1..30}; do
  if remote_compose "exec -T postgres pg_isready -h 127.0.0.1 -U ${DEPLOY_DATABASE_USER}" >/dev/null 2>&1; then break; fi
  sleep 2
done

if ! remote_compose "exec -T postgres pg_isready -h 127.0.0.1 -U ${DEPLOY_DATABASE_USER}" >/dev/null 2>&1; then
  echo -e "${RED}❌ 数据库容器未就绪${NC}"; exit 1
fi

BACKUP_FILE="backups/${DEPLOY_DATABASE_NAME}_$(date +%Y%m%d_%H%M%S).sql.gz"
echo -e "${YELLOW}2) 备份数据库...${NC}"
ssh "$SERVER" "set -o pipefail; cd $REMOTE_DIR && mkdir -p backups && \
  docker compose -p $STACK_NAME -f $COMPOSE_FILE --env-file scripts/deploy-release/runtime/.env \
  exec -T postgres pg_dump -h 127.0.0.1 -U ${DEPLOY_DATABASE_USER} ${DEPLOY_DATABASE_NAME} \
  | gzip > ${BACKUP_FILE}" \
  && echo -e "${GREEN}✅ 备份完成: ${BACKUP_FILE}${NC}" \
  || echo -e "${YELLOW}⚠️ 备份跳过（首次部署）${NC}"

echo -e "${YELLOW}3) 检查数据库是否已初始化...${NC}"
db_exists=$(remote_compose "exec -T postgres psql -h 127.0.0.1 -U ${DEPLOY_DATABASE_USER} \
  -tAc \"SELECT 1 FROM pg_database WHERE datname='${DEPLOY_DATABASE_NAME}'\"" | tr -d '[:space:]')
if [[ "$db_exists" != "1" ]]; then
  remote_compose "exec -T postgres psql -h 127.0.0.1 -U ${DEPLOY_DATABASE_USER} \
    -c \"CREATE DATABASE ${DEPLOY_DATABASE_NAME};\""
  echo -e "${GREEN}  ✅ 数据库已创建（首次部署）${NC}"
fi

remote_compose "exec -T postgres psql -h 127.0.0.1 -U ${DEPLOY_DATABASE_USER} -d ${DEPLOY_DATABASE_NAME} \
  -c \"CREATE TABLE IF NOT EXISTS schema_migrations (version VARCHAR(32) PRIMARY KEY, applied_at TIMESTAMPTZ DEFAULT NOW());\""

echo -e "${GREEN}✅ DB 发布完成${NC}"
