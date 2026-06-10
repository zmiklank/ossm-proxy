set -euo pipefail

sysctl -w user.max_user_namespaces=15000

git clone ${SOURCE_REPO} proxy-src
cd proxy-src
git checkout ${SOURCE_REF}

LOCAL_JOBS=$(( $(nproc) * 3 / 4 ))
LOCAL_RAM=$(( $(free -m | awk '/^Mem:/{print $2}') * 85 / 100 ))

CNAME="ossm-build-$$"
cleanup_container() { podman rm -f "${CNAME}" 2>/dev/null || true; }
trap cleanup_container EXIT

# Start container without --rm so we can exec into it twice:
# once for pre-submit (build + test) and once for envoy_tar packaging.
podman run -d --name "${CNAME}" --privileged \
  -e CI=true \
  -e LOCAL_JOBS="${LOCAL_JOBS}" \
  -e LOCAL_CPU_RESOURCES="$(nproc)" \
  -e LOCAL_RAM_RESOURCES="${LOCAL_RAM}" \
  -v "$(pwd)":/work:z -w /work \
  $(cat ossm/ci/builder-image) \
  sleep infinity

TMPLOG=$(mktemp)

# Phase 1: build + test (equivalent to Prow pre-submit)
podman exec --workdir /work "${CNAME}" \
  bash ossm/ci/pre-submit.sh > "${TMPLOG}" 2>&1
EXIT_CODE=$?

if [[ ${EXIT_CODE} -eq 0 ]]; then
  echo "=== Build succeeded — first 300 lines ==="
  head -300 "${TMPLOG}"
  echo "=== Build succeeded — last 300 lines ==="
  tail -300 "${TMPLOG}"

  # Phase 2: package the release artifact using the warm Bazel cache (~15s).
  # The result is stored in $TMT_TEST_DATA, accessible from the RH internal network
  # at artifacts.osci.redhat.com. Note: GitHub Actions runners cannot access
  # that host (private RH network) so this is for manual inspection only.
  echo "=== Packaging release artifact (envoy_tar) ==="
  SHA=$(podman exec --workdir /work "${CNAME}" git rev-parse --verify HEAD)
  ARCH=$(podman exec --workdir /work "${CNAME}" uname -m)
  [[ "${ARCH}" == "aarch64" ]] && ARCH_SUFFIX="-arm64" || ARCH_SUFFIX=""
  ARTIFACT="envoy-alpha-${SHA}${ARCH_SUFFIX}.tar.gz"

  podman exec --workdir /work "${CNAME}" \
    bash -c 'source ossm/ci/common.sh && bazel_build envoy_tar' >> "${TMPLOG}" 2>&1

  podman exec --workdir /work "${CNAME}" \
    cp -L bazel-bin/envoy_tar.tar.gz "/work/${ARTIFACT}"

  cp "${ARTIFACT}" "${TMT_TEST_DATA}/${ARTIFACT}"
  echo "Release artifact: ${ARTIFACT} ($(du -sh "${ARTIFACT}" | cut -f1))"

else
  echo "=== Build FAILED — full output ==="
  cat "${TMPLOG}"
fi

rm -f "${TMPLOG}"
exit ${EXIT_CODE}
