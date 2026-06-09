
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
        sha256 = "9fdedf05bb8587bb7c8c2581ee2b06d4853772efd27337a6e18d347c47928dd5",
        strip_prefix = "envoy-openssl-5f6b7c86993a69a46c6dbb60ce0a193e7f582b23",
        url = "https://github.com/envoyproxy/envoy-openssl/archive/5f6b7c86993a69a46c6dbb60ce0a193e7f582b23.tar.gz",
        patch_args = ["-p1"],
        patches = [
            "@io_istio_proxy//ossm/patches:use-cmake-from-host.patch",
            ],
    )
