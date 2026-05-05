#!/usr/bin/env bash
# Bootstrap Sensei meta workflows + tools + agent + sensei-core plugin (Serverless 9.5.x).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
AGENT_ID="sensei"
PLUGIN_MANIFEST_NAME="sensei-core"
WORKFLOW_LOGICAL_NAMES=("sensei-install-pack" "sensei-uninstall-pack" "sensei-list-packs")
TOOL_DEFS=(
  "sensei-install-pack-tool:sensei-install-pack-tool.json:sensei-install-pack"
  "sensei-uninstall-pack-tool:sensei-uninstall-pack-tool.json:sensei-uninstall-pack"
  "sensei-list-packs-tool:sensei-list-packs-tool.json:sensei-list-packs"
)
EXPECTED_SKILL_IDS=(
  "sensei-core-how-sensei-works"
  "sensei-core-list-packs"
  "sensei-core-install-pack"
)
META_DIR="${ROOT}/meta"
TOOLS_SRC_DIR="${META_DIR}/tools"
AGENT_JSON="${ROOT}/agents/sensei.json"
WORKFLOW_TAG_FILTER="sensei-meta"
PLAN=false
FORCE=false
MODE="execute"
START_EPOCH="$(date +%s)"
http_last_body=""
http_last_code=""
usage() {
  cat <<'USAGE' >&2
Usage: install-sensei.sh [--plan] [--force]
  --plan    Print planned actions only (no writes).
  --force   Teardown Sensei bootstrap artifacts on the cluster, then recreate.
Environment:
  Loads .env from the repository root (next to meta/ and agents/).
  Required: KIBANA_URL, KIBANA_API_KEY
  Optional: KIBANA_SPACE_ID (non-default Kibana space)
USAGE
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan) PLAN=true ;;
    --force) FORCE=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done
[[ "${PLAN}" == true ]] && MODE="plan"
source_env() {
  local env_file="${ROOT}/.env"
  if [[ ! -f "${env_file}" ]]; then
    echo "Error: ${env_file} not found. Copy .env.example to .env and fill in values." >&2
    exit 1
  fi
  set -a
  # shellcheck disable=SC1091
  source "${env_file}"
  set +a
}
preflight() {
  source_env
  : "${KIBANA_URL:?Set KIBANA_URL in .env}"
  : "${KIBANA_API_KEY:?Set KIBANA_API_KEY in .env}"
  space_prefix=""
  if [[ -n "${KIBANA_SPACE_ID:-}" && "${KIBANA_SPACE_ID}" != "default" ]]; then
    space_prefix="/s/${KIBANA_SPACE_ID}"
  fi
  KIBANA_ROOT="${KIBANA_URL%/}${space_prefix}"
  if [[ ! -d "${META_DIR}" || ! -f "${AGENT_JSON}" ]]; then
    echo "Error: expected ${META_DIR} and ${AGENT_JSON}" >&2
    exit 1
  fi
  kibana_curl GET "/api/status"
  echo "preflight: GET /api/status -> HTTP ${http_last_code}" >&2
  [[ "${http_last_code}" == "200" ]] || { echo "${http_last_body}" >&2; exit 1; }
}
kibana_curl() {
  local method="$1"
  local path="$2"
  local data="${3:-}"
  local tmp code
  tmp="$(mktemp)"
  if [[ -n "${data}" ]]; then
    code="$(curl -sS --max-time 120 -o "${tmp}" -w "%{http_code}" -X "${method}" \
      "${KIBANA_ROOT}${path}" \
      -H "Authorization: ApiKey ${KIBANA_API_KEY}" \
      -H "kbn-xsrf: true" \
      -H "x-elastic-internal-origin: kibana" \
      -H "Content-Type: application/json" \
      --data-binary "${data}")"
  else
    code="$(curl -sS --max-time 120 -o "${tmp}" -w "%{http_code}" -X "${method}" \
      "${KIBANA_ROOT}${path}" \
      -H "Authorization: ApiKey ${KIBANA_API_KEY}" \
      -H "kbn-xsrf: true" \
      -H "x-elastic-internal-origin: kibana")"
  fi
  http_last_body="$(cat "${tmp}")"
  rm -f "${tmp}"
  http_last_code="${code}"
}
fetch_all_pages() {
  local path="$1"
  curl -sS --max-time 120 "${KIBANA_ROOT}/api/${path}?page=1&size=500" \
    -H "Authorization: ApiKey ${KIBANA_API_KEY}" \
    -H "kbn-xsrf: true" \
    -H "x-elastic-internal-origin: kibana" \
    | jq -c '(.results // .)'
}
collect_meta_workflow_map() {
  local raw
  raw="$(fetch_all_pages "workflows")"
  echo "${raw}" | jq -c '
    [.[] | select(
      (((.tags // []) + ((.definition // {}).tags // [])) | index("'"${WORKFLOW_TAG_FILTER}"'")) != null
      and (.name as $n | ["sensei-install-pack","sensei-uninstall-pack","sensei-list-packs"] | index($n) != null)
    ) | {key: .name, value: .id}]
    | from_entries
  '
}
find_plugin_uuid_for_name() {
  local want="$1"
  local raw
  raw="$(fetch_all_pages "agent_builder/plugins")"
  echo "${raw}" | jq -r --arg n "${want}" '[.[] | select(.name == $n) | .id] | first // empty'
}
teardown_sensei_cluster_objects() {
  echo "teardown: removing Sensei bootstrap artifacts..." >&2
  kibana_curl DELETE "/api/agent_builder/agents/${AGENT_ID}"
  echo "  DELETE agent/${AGENT_ID}: HTTP ${http_last_code}" >&2
  local tid
  for tid in sensei-install-pack-tool sensei-uninstall-pack-tool sensei-list-packs-tool; do
    kibana_curl DELETE "/api/agent_builder/tools/${tid}"
    echo "  DELETE tool/${tid}: HTTP ${http_last_code}" >&2
  done
  local wf_map_json count bulk_body
  wf_map_json="$(collect_meta_workflow_map)"
  count="$(echo "${wf_map_json}" | jq '[.[]] | length')"
  if [[ "${count}" != "0" ]]; then
    bulk_body="$(echo "${wf_map_json}" | jq '{ids: [.[]]}')"
    kibana_curl DELETE "/api/workflows" "${bulk_body}"
    echo "  DELETE /api/workflows bulk (${count} ids): HTTP ${http_last_code}" >&2
    [[ "${http_last_code}" == "200" ]] || { echo "${http_last_body}" >&2; exit 3; }
  fi
  local pid
  pid="$(find_plugin_uuid_for_name "${PLUGIN_MANIFEST_NAME}")"
  if [[ -n "${pid}" ]]; then
    kibana_curl DELETE "/api/agent_builder/plugins/${pid}"
    echo "  DELETE plugin/${PLUGIN_MANIFEST_NAME} (${pid}): HTTP ${http_last_code}" >&2
  fi
}
ensure_workflows() {
  local wf_map_json="$1"
  local missing=()
  local n cur
  for n in "${WORKFLOW_LOGICAL_NAMES[@]}"; do
    cur="$(echo "${wf_map_json}" | jq -r --arg k "${n}" '.[$k] // empty')"
    [[ -z "${cur}" ]] && missing+=("${n}")
  done
  if [[ "${#missing[@]}" == "0" ]]; then
    echo "workflows: all meta workflows present; skipping POST." >&2
    echo "${wf_map_json}"
    return 0
  fi
  if [[ "${MODE}" == "plan" ]]; then
    echo "plan: would POST ${#missing[@]} workflow(s) from ${META_DIR}" >&2
    echo "${wf_map_json}"
    return 0
  fi
  echo "workflows: creating: ${missing[*]}" >&2
  local jq_cmd='{"workflows":[]}' m yaml_path
  for m in "${missing[@]}"; do
    yaml_path="${META_DIR}/${m}.yaml"
    [[ -f "${yaml_path}" ]] || { echo "Error: missing ${yaml_path}" >&2; exit 1; }
    jq_cmd="$(jq -n --rawfile y "${yaml_path}" --argjson prev "${jq_cmd}" '$prev | .workflows += [{yaml:$y}]')"
  done
  kibana_curl POST "/api/workflows" "${jq_cmd}"
  echo "workflows: POST /api/workflows -> HTTP ${http_last_code}" >&2
  [[ "${http_last_code}" == "200" ]] || { echo "${http_last_body}" >&2; exit 3; }
  [[ "$(echo "${http_last_body}" | jq '.failed | length')" == "0" ]] || { echo "${http_last_body}" >&2; exit 3; }
  collect_meta_workflow_map
}
ensure_tools() {
  local wf_map_json="$1"
  if [[ "${MODE}" == "plan" ]]; then
    echo "plan: would POST meta tools with patched workflow_id" >&2
    return 0
  fi
  local ent tid fname logical wf_id payload src_json cur_wid
  for ent in "${TOOL_DEFS[@]}"; do
    IFS=: read -r tid fname logical <<<"${ent}"
    wf_id="$(echo "${wf_map_json}" | jq -r --arg k "${logical}" '.[$k]')"
    [[ -n "${wf_id}" && "${wf_id}" != "null" ]] || { echo "Error: no workflow id for ${logical}" >&2; exit 3; }
    src_json="${TOOLS_SRC_DIR}/${fname}"
    payload="$(jq --arg wid "${wf_id}" '.configuration.workflow_id = $wid' "${src_json}")"
    kibana_curl GET "/api/agent_builder/tools/${tid}"
    if [[ "${http_last_code}" == "200" ]]; then
      cur_wid="$(echo "${http_last_body}" | jq -r '.configuration.workflow_id // empty')"
      [[ "${cur_wid}" == "${wf_id}" ]] && { echo "tools: ${tid} OK (workflow_id=${wf_id}); skip." >&2; continue; }
      echo "tools: ${tid} mismatch (have=${cur_wid}, want=${wf_id}); replacing." >&2
      kibana_curl DELETE "/api/agent_builder/tools/${tid}"
    fi
    kibana_curl POST "/api/agent_builder/tools" "${payload}"
    echo "tools: POST ${tid} -> HTTP ${http_last_code}" >&2
    [[ "${http_last_code}" == "200" ]] || { echo "${http_last_body}" >&2; exit 3; }
  done
}
canonical_agent_doc() {
  jq 'del(.type) | walk(if type == "object" then with_entries(select(.key != "type")) else . end)' "${AGENT_JSON}"
}
agent_core_matches_repo() {
  local live_json="$1"
  local live_tmp
  live_tmp="$(mktemp)"
  echo "${live_json}" >"${live_tmp}"
  python3 - "${AGENT_JSON}" "${live_tmp}" <<'PY'
import json, sys
repo = json.load(open(sys.argv[1]))
live = json.load(open(sys.argv[2]))

def core(doc):
    c = doc.get("configuration") or {}
    enable = c.get("enable_elastic_capabilities")
    instructions = c.get("instructions")
    ids = []
    for block in c.get("tools") or []:
        if isinstance(block, dict) and isinstance(block.get("tool_ids"), list):
            ids = sorted(block["tool_ids"])
    return enable, ids, instructions

sys.exit(0 if core(repo) == core(live) else 1)
PY
  local ok=$?
  rm -f "${live_tmp}"
  return "${ok}"
}
merge_put_payload_from_live_file() {
  local live_file="$1"
  local canon_tmp merged
  canon_tmp="$(mktemp)"
  canonical_agent_doc >"${canon_tmp}"
  merged="$(jq --slurpfile r "${canon_tmp}" --slurpfile L "${live_file}" '
    ($r[0]) as $repo | ($L[0]) as $live |
    {
      name: $live.name,
      description: $live.description,
      configuration: {
        instructions: $repo.configuration.instructions,
        tools: $repo.configuration.tools,
        skill_ids: $live.configuration.skill_ids,
        plugin_ids: $live.configuration.plugin_ids,
        enable_elastic_capabilities: $repo.configuration.enable_elastic_capabilities
      }
    }
  ')"
  rm -f "${canon_tmp}"
  echo "${merged}"
}
ensure_agent() {
  if [[ "${MODE}" == "plan" ]]; then
    echo "plan: would ensure agent ${AGENT_ID} from ${AGENT_JSON}" >&2
    return 0
  fi
  local live_tmp merged post_body code
  live_tmp="$(mktemp)"
  kibana_curl GET "/api/agent_builder/agents/${AGENT_ID}"
  if [[ "${http_last_code}" == "200" ]]; then
    echo "${http_last_body}" >"${live_tmp}"
    if agent_core_matches_repo "${http_last_body}"; then
      echo "agent: ${AGENT_ID} matches repo baseline; skip." >&2
      rm -f "${live_tmp}"
      return 0
    fi
    echo "agent: merging repo baseline onto live agent (preserve skill_ids/plugin_ids)." >&2
    merged="$(merge_put_payload_from_live_file "${live_tmp}")"
    rm -f "${live_tmp}"
    kibana_curl PUT "/api/agent_builder/agents/${AGENT_ID}" "${merged}"
    echo "agent: PUT ${AGENT_ID} -> HTTP ${http_last_code}" >&2
    [[ "${http_last_code}" == "200" ]] || { echo "${http_last_body}" >&2; exit 3; }
    return 0
  fi
  post_body="$(canonical_agent_doc)"
  kibana_curl POST "/api/agent_builder/agents" "${post_body}"
  code="${http_last_code}"
  echo "agent: POST ${AGENT_ID} -> HTTP ${code}" >&2
  if [[ "${code}" == "200" ]]; then
    rm -f "${live_tmp}"
    return 0
  fi
  if [[ "${code}" == "409" || "${code}" == "400" ]]; then
    kibana_curl GET "/api/agent_builder/agents/${AGENT_ID}"
    [[ "${http_last_code}" == "200" ]] || { echo "${http_last_body}" >&2; rm -f "${live_tmp}"; exit 3; }
    echo "${http_last_body}" >"${live_tmp}"
    merged="$(merge_put_payload_from_live_file "${live_tmp}")"
    rm -f "${live_tmp}"
    kibana_curl PUT "/api/agent_builder/agents/${AGENT_ID}" "${merged}"
    echo "agent: PUT ${AGENT_ID} (after POST conflict) -> HTTP ${http_last_code}" >&2
    [[ "${http_last_code}" == "200" ]] || { echo "${http_last_body}" >&2; exit 3; }
    return 0
  fi
  rm -f "${live_tmp}"
  echo "${http_last_body}" >&2
  exit 3
}
install_sensei_core_via_tool() {
  if [[ "${MODE}" == "plan" ]]; then
    echo "plan: would POST /api/agent_builder/tools/_execute (install ${PLUGIN_MANIFEST_NAME})" >&2
    return 0
  fi
  if skills_complete_on_agent && [[ -n "$(find_plugin_uuid_for_name "${PLUGIN_MANIFEST_NAME}")" ]]; then
    echo "install: sensei-core already present; skip _execute." >&2
    return 0
  fi
  local payload
  payload="$(jq -n \
    --arg tid "sensei-install-pack-tool" \
    --arg pack "${PLUGIN_MANIFEST_NAME}" \
    --arg aid "${AGENT_ID}" \
    '{tool_id:$tid, tool_params:{pack_id:$pack, agent_id:$aid}}')"
  kibana_curl POST "/api/agent_builder/tools/_execute" "${payload}"
  echo "install: POST tools/_execute -> HTTP ${http_last_code}" >&2
  [[ "${http_last_code}" == "200" ]] || { echo "${http_last_body}" >&2; exit 3; }
}
skills_complete_on_agent() {
  kibana_curl GET "/api/agent_builder/agents/${AGENT_ID}"
  [[ "${http_last_code}" == "200" ]] || return 1
  local sid missing=0
  for sid in "${EXPECTED_SKILL_IDS[@]}"; do
    echo "${http_last_body}" | jq -e --arg s "${sid}" '.configuration.skill_ids | index($s)' >/dev/null || missing=1
  done
  return "${missing}"
}
verify_final_state() {
  [[ "${MODE}" == "plan" ]] && return 0
  kibana_curl GET "/api/agent_builder/agents/${AGENT_ID}"
  echo "verify: GET agents/${AGENT_ID} -> HTTP ${http_last_code}" >&2
  [[ "${http_last_code}" == "200" ]] || exit 3
  local sid
  for sid in "${EXPECTED_SKILL_IDS[@]}"; do
    echo "${http_last_body}" | jq -e --arg s "${sid}" '.configuration.skill_ids | index($s)' >/dev/null || {
      echo "verify: missing skill ${sid}" >&2
      exit 3
    }
  done
  local raw
  raw="$(fetch_all_pages "agent_builder/plugins")"
  echo "${raw}" | jq -e --arg n "${PLUGIN_MANIFEST_NAME}" '.[] | select(.name == $n)' >/dev/null || {
    echo "verify: plugin ${PLUGIN_MANIFEST_NAME} missing" >&2
    exit 3
  }
  echo "verify: OK (agent skills + plugin)." >&2
}
main() {
  preflight
  echo "==> Sensei install (${ROOT})" >&2
  echo "    Kibana: ${KIBANA_ROOT}" >&2
  if [[ "${FORCE}" == true ]]; then
    if [[ "${MODE}" == "plan" ]]; then
      echo "plan: --force would teardown Sensei bootstrap artifacts first." >&2
    else
      teardown_sensei_cluster_objects
    fi
  fi
  local wf_map_json wf_map2
  wf_map_json="$(collect_meta_workflow_map)"
  wf_map2="$(ensure_workflows "${wf_map_json}")"
  ensure_tools "${wf_map2}"
  ensure_agent
  install_sensei_core_via_tool
  verify_final_state
  local elapsed=$(( $(date +%s) - START_EPOCH ))
  echo "" >&2
  echo "Done in ${elapsed}s. Agent: ${AGENT_ID}. Plugin: ${PLUGIN_MANIFEST_NAME}." >&2
}
main "$@"
