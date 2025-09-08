
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
        sha256 = "1d48fa0260a67bdf39aa2b4a6390249cc8bc21fe24bf0de90110d0eca9e721cf",
        strip_prefix = "envoy-openssl-da5ba3ed17c672fd8fe1a8963f1b2cf506b75476",
        url = "https://github.com/envoyproxy/envoy-openssl/archive/da5ba3ed17c672fd8fe1a8963f1b2cf506b75476.tar.gz",
        patch_args = ["-p1"],
        patches = [
            "@io_istio_proxy//ossm/patches:use-cmake-from-host.patch",
            ],
    )
