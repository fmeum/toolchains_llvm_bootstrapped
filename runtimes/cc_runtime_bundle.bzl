load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

def _cc_runtime_bundle_impl(ctx):
    deps_cc_infos = [dep[CcInfo] for dep in ctx.attr.deps]
    merged = cc_common.merge_cc_infos(cc_infos = deps_cc_infos)
    merged_compilation = merged.compilation_context
    if merged_compilation:
        defines = depset(transitive = [
            merged_compilation.defines,
            merged_compilation.local_defines,
        ])
        local_defines = merged_compilation.local_defines
    else:
        defines = depset()
        local_defines = depset()
    sanitized_compilation = cc_common.create_compilation_context(
        headers = depset(),
        system_includes = depset(),
        quote_includes = depset(),
        framework_includes = depset(),
        includes = depset(),
        defines = defines,
        local_defines = local_defines,
    )
    return [
        CcInfo(
            compilation_context = sanitized_compilation,
            linking_context = merged.linking_context,
        ),
        DefaultInfo(),
    ]

cc_runtime_bundle = rule(
    implementation = _cc_runtime_bundle_impl,
    attrs = {
        "deps": attr.label_list(providers = [CcInfo]),
    },
)
