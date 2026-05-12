set -euo pipefail

sysctl -w user.max_user_namespaces=15000

git clone ${SOURCE_REPO} proxy-src
cd proxy-src
git checkout ${SOURCE_REF}
LOCAL_JOBS=$(( $(nproc) * 3 / 4 ))
LOCAL_RAM=$(( $(free -m | awk '/^Mem:/{print $2}') * 85 / 100 ))

TMPLOG=$(mktemp)
podman run --rm --privileged \
  -e CI=true \
  -e LOCAL_JOBS="${LOCAL_JOBS}" \
  -e LOCAL_CPU_RESOURCES="$(nproc)" \
  -e LOCAL_RAM_RESOURCES="${LOCAL_RAM}" \
  -v "$(pwd)":/work:z -w /work \
  quay.io/maistra-dev/maistra-builder:3.3 \
  bash ossm/ci/pre-submit.sh > "${TMPLOG}" 2>&1
EXIT_CODE=$?

if [[ ${EXIT_CODE} -eq 0 ]]; then
  echo "=== Build succeeded — first 300 lines ==="
  head -300 "${TMPLOG}"
  echo "=== Build succeeded — last 300 lines ==="
  tail -300 "${TMPLOG}"
else
  echo "=== Build FAILED — full output ==="
  cat "${TMPLOG}"
fi

rm -f "${TMPLOG}"
exit ${EXIT_CODE}
