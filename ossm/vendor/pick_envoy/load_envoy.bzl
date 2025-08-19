
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

OPENSSL_DISABLED_EXTENSIONS = [
            "envoy.tls.key_providers.cryptomb",
            "envoy.tls.key_providers.qat",
            "envoy.quic.deterministic_connection_id_generator",
            "envoy.quic.crypto_stream.server.quiche",
            "envoy.quic.proof_source.filter_chain",
        ]

def load_envoy():
    http_archive(
        name = "envoy",
        sha256 = "15c1baecd8a06f851a2e311d90d8fcca7e97d204e90cefb98abd29eb05daa10f",
        strip_prefix = "envoy-openssl-bfe0463d44a2e58911345edcf5fa52d3c97d3a65",
        url = "https://github.com/envoyproxy/envoy-openssl/archive/bfe0463d44a2e58911345edcf5fa52d3c97d3a65.tar.gz",
        patch_args = ["-p1"],
        patches = [
            "@io_istio_proxy//ossm/patches:use-cmake-from-host.patch",
            ],
    )
