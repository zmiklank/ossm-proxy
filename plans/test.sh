set -euo pipefail

sysctl -w user.max_user_namespaces=15000

git clone ${SOURCE_REPO} proxy-src
cd proxy-src
git checkout ${SOURCE_REF}
LOCAL_JOBS=$(( $(nproc) * 3 / 4 ))
LOCAL_RAM=$(( $(free -m | awk '/^Mem:/{print $2}') * 85 / 100 ))

podman run --rm --privileged \
  -e CI=true \
  -e LOCAL_JOBS="${LOCAL_JOBS}" \
  -e LOCAL_CPU_RESOURCES="$(nproc)" \
  -e LOCAL_RAM_RESOURCES="${LOCAL_RAM}" \
  -v "$(pwd)":/work:z -w /work \
  quay.io/maistra-dev/maistra-builder:3.3 \
  bash ossm/ci/pre-submit.sh
