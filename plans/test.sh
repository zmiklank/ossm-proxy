set -euo pipefail

git clone ${SOURCE_REPO} proxy-src
cd proxy-src
git checkout ${SOURCE_REF}
podman run --rm --privileged \
  -v "$(pwd)":/work:z -w /work \
  quay.io/maistra-dev/maistra-builder:3.3 \
  bash ossm/ci/pre-submit.sh
