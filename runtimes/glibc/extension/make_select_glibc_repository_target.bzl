load("//constraints/libc:libc_versions.bzl", "GLIBCS", "UNSUPPORTED_GLIBC_ERROR", "glibc_supported")
load("//platforms:common.bzl", "LIBC_SUPPORTED_TARGETS")
load(":glibc.bzl", "glibc_triple")

def declare_glibc_repository_target(name, bazel_repository, bazel_target, architecture_specific = True, **kwargs):
    """Select a target architecture before selecting its glibc version."""
    targets = {}
    for (target_os, target_arch) in LIBC_SUPPORTED_TARGETS:
        triple = glibc_triple(target_os, target_arch)

        versions = {}
        for glibc in GLIBCS:
            # The glibc repos are keyed by the numeric version only.
            glibc_version = glibc.removeprefix("gnu.")
            if not glibc_supported(target_arch, glibc_version):
                continue
            repository = "{}_{}.{}".format(bazel_repository, triple, glibc_version) if architecture_specific else "{}_{}".format(bazel_repository, glibc_version)
            versions["@llvm//platforms/config:{}".format(glibc)] = "{}//:{}".format(repository, bazel_target)

        target_name = "{}_{}_{}".format(name, target_os, target_arch)
        native.alias(
            name = target_name,
            actual = select(versions, no_match_error = UNSUPPORTED_GLIBC_ERROR),
            visibility = ["//visibility:private"],
        )
        targets["@llvm//platforms/config:{}_{}".format(target_os, target_arch)] = target_name

    native.alias(
        name = name,
        actual = select(targets),
        **kwargs
    )
