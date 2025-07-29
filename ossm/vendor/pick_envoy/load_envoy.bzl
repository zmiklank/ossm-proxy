
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
        sha256 = "61c0ce3abb902d840e54f113b4923e564a4fa30428c3c4b8383a799c9194d9d0",
        strip_prefix = "envoy-openssl-7c7e48356319b6882a80033d025e0adf4d1bcf69",
        url = "https://github.com/envoyproxy/envoy-openssl/archive/7c7e48356319b6882a80033d025e0adf4d1bcf69.tar.gz",
        patch_args = ["-p1"],
        patches = [
            "@io_istio_proxy//ossm/patches:use-cmake-from-host.patch",
            ],
    )
