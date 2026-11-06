load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@platforms_contrib//os/linux/libc:libc.bzl", "PreferredLibcInfo", "check_preferred_libc")
load("//constraints/libc:libc_versions.bzl", "DEFAULT_LIBC", "GLIBC_VERSIONS", "LIBCS")
load("//platforms:common.bzl", "LIBC_SUPPORTED_TARGETS")

_GLIBC = "@platforms_contrib//os/linux/libc/glibc:"
_MUSL = "@platforms_contrib//os/linux/libc/musl:"

# The value for platforms that only make glibc versions older than the supported ones available.
UNSUPPORTED_GLIBC = "gnu.unsupported"

def _has(ctx, constraint_value):
    return ctx.target_platform_has_constraint(constraint_value[platform_common.ConstraintValueInfo])

def _target_libc(ctx):
    if not _has(ctx, ctx.attr._linux) or not any([_has(ctx, cpu) for cpu in ctx.attr._cpus]):
        return "none"
    for libc, constraint_value in zip(LIBCS, ctx.attr._legacy_libcs):
        if _has(ctx, constraint_value):
            return libc

    glibc_available = _has(ctx, ctx.attr._glibc_available)
    musl_available = _has(ctx, ctx.attr._musl_available)

    # Platforms without libc constraints use the default libc unless a fully static option is ranked.
    preferred_libc = ctx.attr._preferred_libc[PreferredLibcInfo]
    if preferred_libc.status == "unresolved" and not glibc_available and not musl_available:
        return DEFAULT_LIBC

    check_preferred_libc(preferred_libc)
    if preferred_libc.flavor == "none":
        # Compiler-rt is built against the headers of a libc, but the objects that freestanding code
        # needs don't call into it.
        return "none" if ctx.attr._runtime_stage[BuildSettingInfo].value == "complete" else "musl"
    if preferred_libc.flavor == "musl":
        return "musl"
    if not glibc_available:
        return DEFAULT_LIBC
    for version, at_least in reversed(list(zip(GLIBC_VERSIONS, ctx.attr._glibc_at_least))):
        if _has(ctx, at_least):
            return "gnu." + version
    return UNSUPPORTED_GLIBC

def _target_libc_impl(ctx):
    libc = _target_libc(ctx)
    if ctx.attr.family:
        libc = libc.partition(".")[0]
    return [config_common.FeatureFlagInfo(value = libc)]

target_libc = rule(
    implementation = _target_libc_impl,
    doc = """Provides the libc that Linux targets compile against for config_setting.flag_values.

A //constraints/libc value on the target platform takes precedence. Otherwise, the libc is the one
chosen by @platforms_contrib//os/linux/libc:preference, which can also be "none", or DEFAULT_LIBC if
the platform has no libc constraints and no option is viable. For glibc, it's the newest supported
version that the platform makes available, or DEFAULT_LIBC if it has no glibc constraints.
""",
    attrs = {
        "family": attr.bool(doc = "Whether to omit the glibc version."),
        "_cpus": attr.label_list(default = [
            "@platforms//cpu:" + target_cpu
            for (target_os, target_cpu) in LIBC_SUPPORTED_TARGETS
            if target_os == "linux"
        ]),
        "_glibc_at_least": attr.label_list(default = [
            _GLIBC + "at_least_{}_available".format(version)
            for version in GLIBC_VERSIONS
        ]),
        "_glibc_available": attr.label(default = _GLIBC + "available"),
        "_legacy_libcs": attr.label_list(default = ["//constraints/libc:" + libc for libc in LIBCS]),
        "_preferred_libc": attr.label(default = "@platforms_contrib//os/linux/libc:preferred"),
        "_linux": attr.label(default = "@platforms//os:linux"),
        "_musl_available": attr.label(default = _MUSL + "available"),
        "_runtime_stage": attr.label(default = "//toolchain:runtime_stage"),
    },
)
