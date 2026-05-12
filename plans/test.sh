set -euo pipefail

sysctl -w user.max_user_namespaces=15000

git clone ${SOURCE_REPO} proxy-src
cd proxy-src
git checkout ${SOURCE_REF}
BAZEL_JOBS=$(( $(nproc) * 3 / 4 ))

podman run --rm --privileged \
  -e BAZEL_JOBS="${BAZEL_JOBS}" \
  -v "$(pwd)":/work:z -w /work \
  quay.io/maistra-dev/maistra-builder:3.3 \
  bash ossm/ci/pre-submit.sh
