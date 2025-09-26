
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
        sha256 = "e04ee3e62546dee80a0bd77df16580cb5f177ba351bde2cb3a5de9c82af3a2a4",
        strip_prefix = "envoy-openssl-81c075bd2f6707867eded284e205cddef4f09a68",
        url = "https://github.com/envoyproxy/envoy-openssl/archive/81c075bd2f6707867eded284e205cddef4f09a68.tar.gz",
        patch_args = ["-p1"],
        patches = [
            "@io_istio_proxy//ossm/patches:use-cmake-from-host.patch",
            ],
    )
