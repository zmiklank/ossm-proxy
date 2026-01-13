
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
        sha256 = "5d9799078e5ef1f785b5f0c66e80615a35db31afc2009475b49242bedebccd8a",
        strip_prefix = "envoy-openssl-b959723e30e2302f4d3baa3279ab9b014c422ffc",
        url = "https://github.com/envoyproxy/envoy-openssl/archive/b959723e30e2302f4d3baa3279ab9b014c422ffc.tar.gz",
        patch_args = ["-p1"],
        patches = [
            "@io_istio_proxy//ossm/patches:use-cmake-from-host.patch",
            ],
    )
