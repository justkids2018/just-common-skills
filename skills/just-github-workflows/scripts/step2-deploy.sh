#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/deploy-release/bin/common.sh
source "$SCRIPT_DIR/bin/common.sh"

PROFILE_NAME="${1:-}"
load_profile "$PROFILE_NAME"

print_header "Step 2/2 - 同步并部署到服务器 (${DEPLOY_PROVIDER})"

if [[ ! -f "$LOCAL_LATEST_DIR/deploy.env" ]]; then
  echo -e "${RED}❌ 未找到部署产物，请先执行 step1-prepare.sh${NC}"; exit 1
fi

ensure_ssh
preflight_conflict_check
sync_deploy_assets

ssh "$SERVER" "mkdir -p $REMOTE_DIR/scripts/deploy-release/runtime"
scp "$LOCAL_LATEST_DIR/deploy.env" "$SERVER:$REMOTE_DIR/scripts/deploy-release/runtime/.env" >/dev/null

echo -e "${YELLOW}执行数据库发布...${NC}"
"$SCRIPT_DIR/db-release.sh" "$PROFILE_NAME"

echo -e "${YELLOW}拉取镜像并启动服务...${NC}"
remote_compose "pull backend admin"
remote_compose "up -d postgres backend admin"

echo -e "${YELLOW}状态检查...${NC}"
remote_compose "ps"

API_CODE=$(ssh "$SERVER" \
  "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:${DEPLOY_BACKEND_HOST_PORT}/health 2>/dev/null || echo 000")
if [[ "$API_CODE" == "200" ]]; then
  echo -e "${GREEN}✅ 后端健康检查通过 (HTTP ${API_CODE})${NC}"
else
  echo -e "${YELLOW}⚠️ 后端健康检查返回: HTTP ${API_CODE}（首次部署可能正常）${NC}"
fi

echo -e "${GREEN}✅ Step 2 完成${NC}"
