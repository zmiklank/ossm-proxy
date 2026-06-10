set -euo pipefail

# Release build script: builds envoy_tar and uploads directly to GCS from the
# TF machine (which has internet access). Equivalent to ossm/ci/post-submit.sh.
# The GCS service account key is passed as GCS_KEY_JSON_B64 (base64-encoded JSON)
# via a TF secret. If the key is not set, the GCS upload is skipped.

sysctl -w user.max_user_namespaces=15000

git clone ${SOURCE_REPO} proxy-src
cd proxy-src
git checkout ${SOURCE_REF}

LOCAL_JOBS=$(( $(nproc) * 3 / 4 ))
LOCAL_RAM=$(( $(free -m | awk '/^Mem:/{print $2}') * 85 / 100 ))

CNAME="ossm-release-$$"
cleanup_container() { podman rm -f "${CNAME}" 2>/dev/null || true; }
trap cleanup_container EXIT

podman run -d --name "${CNAME}" --privileged \
  -e CI=true \
  -e LOCAL_JOBS="${LOCAL_JOBS}" \
  -e LOCAL_CPU_RESOURCES="$(nproc)" \
  -e LOCAL_RAM_RESOURCES="${LOCAL_RAM}" \
  -v "$(pwd)":/work:z -w /work \
  $(cat ossm/ci/builder-image) \
  sleep infinity

TMPLOG=$(mktemp)

echo "=== Building release artifact (envoy_tar) ==="
podman exec --workdir /work "${CNAME}" \
  bash -c 'source ossm/ci/common.sh && bazel_build envoy_tar' > "${TMPLOG}" 2>&1
EXIT_CODE=$?

if [[ ${EXIT_CODE} -eq 0 ]]; then
  SHA=$(podman exec --workdir /work "${CNAME}" git rev-parse --verify HEAD)
  ARCH=$(podman exec --workdir /work "${CNAME}" uname -m)
  [[ "${ARCH}" == "aarch64" ]] && ARCH_SUFFIX="-arm64" || ARCH_SUFFIX=""
  ARTIFACT="envoy-alpha-${SHA}${ARCH_SUFFIX}.tar.gz"

  podman exec --workdir /work "${CNAME}" \
    cp -L bazel-bin/envoy_tar.tar.gz "/work/${ARTIFACT}"

  echo "=== Build output — first 300 lines ==="
  head -300 "${TMPLOG}"
  echo "=== Build output — last 300 lines ==="
  tail -300 "${TMPLOG}"
  echo "Artifact built: ${ARTIFACT} ($(du -sh "${ARTIFACT}" | cut -f1))"
  cp "${ARTIFACT}" "${TMT_TEST_DATA}/${ARTIFACT}"

else
  echo "=== Build FAILED — full output ==="
  cat "${TMPLOG}"
fi

rm -f "${TMPLOG}"
exit ${EXIT_CODE}
