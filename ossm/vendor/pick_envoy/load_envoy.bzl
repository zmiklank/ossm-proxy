
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
        sha256 = "e24bb3dbeb70b62349baefa6bb0dbb5f946d906a57acd0d79537527246d8c537",
        strip_prefix = "envoy-openssl-8a1a2da18b40cbfc4a7e91c8057d0ae8035bb0db",
        url = "https://github.com/envoyproxy/envoy-openssl/archive/8a1a2da18b40cbfc4a7e91c8057d0ae8035bb0db.tar.gz",
        patch_args = ["-p1"],
        patches = [
            "@io_istio_proxy//ossm/patches:use-cmake-from-host.patch",
            ],
    )
