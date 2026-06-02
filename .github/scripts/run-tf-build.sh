#!/usr/bin/env bash
# Submits a Testing Farm bare metal build request and waits for completion.
#
# Required env vars: TESTING_FARM_API_TOKEN, GH_TOKEN, GIT_REF,
#                    SOURCE_REPO, SOURCE_REF, ARCH
# Optional env vars: PR_NUMBER, PR_COMMIT_SHA
# GHA env vars used: GITHUB_OUTPUT, GITHUB_STEP_SUMMARY, GITHUB_REPOSITORY

set -euo pipefail

if [[ "${ARCH}" == "aarch64" ]]; then
  STATUS_NAME="Testing Farm bare metal arm64"
else
  STATUS_NAME="Testing Farm bare metal"
fi

API_URL="https://api.testing-farm.io/v0.1"
TIMEOUT_MIN=120

REQ_ID=""
tf_cancel() {
  [[ -n "${REQ_ID}" ]] && \
    TESTING_FARM_API_URL="${API_URL}" testing-farm cancel "${REQ_ID}" 2>/dev/null || true
}
trap tf_cancel EXIT

set_pr_status() {
  local state="$1" description="$2"
  [[ -z "${PR_COMMIT_SHA:-}" ]] && return 0
  gh api "repos/${GITHUB_REPOSITORY}/statuses/${PR_COMMIT_SHA}" \
    -f state="${state}" \
    -f context="${STATUS_NAME}" \
    -f description="${description}" \
    -f target_url="${ARTIFACTS_URL:-}" || true
}

ARTIFACTS_URL=""
set_pr_status "pending" "Build running on Testing Farm bare metal..."

echo "Submitting TF request (arch: ${ARCH}, bare metal via hardware constraint)..."
set +e
REQ_OUTPUT=$(TESTING_FARM_API_URL="${API_URL}" testing-farm request \
  --compose "CentOS-Stream-10" \
  --arch "${ARCH}" \
  --hardware "virtualization.is-virtualized=false" \
  --git-url "https://github.com/openshift-service-mesh/proxy.git" \
  --git-ref "${GIT_REF}" \
  --plan "/plans/build" \
  --environment "SOURCE_REPO=${SOURCE_REPO}" \
  --environment "SOURCE_REF=${SOURCE_REF}" \
  --timeout "${TIMEOUT_MIN}" \
  --no-wait 2>&1)
TF_RC=$?
set -e
echo "${REQ_OUTPUT}"
[[ ${TF_RC} -ne 0 ]] && { echo "ERROR: testing-farm request failed (exit ${TF_RC})"; exit ${TF_RC}; }

REQ_ID=$(echo "${REQ_OUTPUT}" | grep -oP 'requests/\K[a-f0-9-]+' | head -1 || true)
[[ -z "${REQ_ID}" ]] && { echo "ERROR: Could not extract request ID"; exit 1; }

ARTIFACTS_URL="https://artifacts.dev.testing-farm.io/${REQ_ID}"
echo "request_id=${REQ_ID}"          >> "${GITHUB_OUTPUT}"
echo "artifacts_url=${ARTIFACTS_URL}" >> "${GITHUB_OUTPUT}"
echo "source_ref=${SOURCE_REF}"       >> "${GITHUB_OUTPUT}"
echo "Request ID: ${REQ_ID}"
echo "Artifacts:  ${ARTIFACTS_URL}"

DEADLINE=$(( $(date +%s) + TIMEOUT_MIN * 60 ))
POLL=0
while true; do
  POLL=$(( POLL + 1 ))
  ELAPSED=$(( $(date +%s) - (DEADLINE - TIMEOUT_MIN * 60) ))
  echo "Poll #${POLL} elapsed=${ELAPSED}s ..."

  set +e
  OUT=$(TESTING_FARM_API_URL="${API_URL}" testing-farm list \
        --id "${REQ_ID}" --format json 2>&1)
  LIST_RC=$?
  set -e
  if [[ ${LIST_RC} -ne 0 ]]; then
    echo "Warning: testing-farm list failed, retrying..."; sleep 30; continue
  fi

  STATE=$(echo "${OUT}" | jq -r '.[0].state // empty')
  RESULT=$(echo "${OUT}" | jq -r '.[0].result.overall // empty')
  echo "  state=${STATE:-?} result=${RESULT:-?}"

  if [[ "${STATE}" =~ ^(complete|error|canceled)$ ]]; then
    API_ARTS=$(echo "${OUT}" | jq -r '.[0].run.artifacts // empty')
    [[ -n "${API_ARTS}" && "${API_ARTS}" != "null" ]] && ARTIFACTS_URL="${API_ARTS}"
    echo "artifacts_url=${ARTIFACTS_URL}" >> "${GITHUB_OUTPUT}"

    {
      echo "## ${STATUS_NAME}"
      echo "| Field | Value |"
      echo "|-------|-------|"
      echo "| Request ID | \`${REQ_ID}\` |"
      echo "| State | ${STATE} |"
      echo "| Result | ${RESULT:-n/a} |"
      echo "| Artifacts | [View](${ARTIFACTS_URL}) |"
    } >> "${GITHUB_STEP_SUMMARY}"

    if [[ -n "${PR_NUMBER:-}" ]]; then
      gh pr comment "${PR_NUMBER}" \
        --repo "${GITHUB_REPOSITORY}" \
        --body "**${STATUS_NAME}** (\`${REQ_ID}\`): state **${STATE}**, result **${RESULT:-n/a}** - [Artifacts](${ARTIFACTS_URL})" \
        || true
    fi

    case "${STATE}:${RESULT}" in
      complete:passed) set_pr_status "success" "Build passed" ;;
      complete:*)      set_pr_status "failure" "Build failed: ${RESULT:-unknown}" ;;
      *)               set_pr_status "error"   "TF ${STATE}" ;;
    esac

    trap - EXIT; REQ_ID=""
    [[ "${STATE}" == "complete" && "${RESULT}" == "passed" ]] && exit 0 || exit 1
  fi

  if (( $(date +%s) > DEADLINE )); then
    echo "TIMEOUT after ${TIMEOUT_MIN} minutes"
    set_pr_status "error" "Timeout after ${TIMEOUT_MIN} min"
    exit 1
  fi

  sleep 30
done
