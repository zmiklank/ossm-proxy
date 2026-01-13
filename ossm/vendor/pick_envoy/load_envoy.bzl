
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
        sha256 = "85b4a7c02b2964182c5b57f2fa39de3964e40a894fd2df2be946dbc349e97996",
        strip_prefix = "envoy-openssl-3cb33a0f10ae9c251785f6dbebcc2f12ffb7d82f",
        url = "https://github.com/envoyproxy/envoy-openssl/archive/3cb33a0f10ae9c251785f6dbebcc2f12ffb7d82f.tar.gz",
        patch_args = ["-p1"],
        patches = [
            "@io_istio_proxy//ossm/patches:use-cmake-from-host.patch",
            ],
    )
