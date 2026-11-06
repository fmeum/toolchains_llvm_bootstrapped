_LIBC = str(Label("@platforms_contrib//os/linux/libc:preference"))
_CXX_RUNTIME = str(Label("@rules_cc//cc/cxx_runtime:preference"))
_PLATFORMS = "//command_line_option:platforms"

def _linkage_transition_impl(settings, attr):
    return {
        _CXX_RUNTIME: attr.cxx_runtime_preference,
        _LIBC: attr.libc_preference or settings[_LIBC],
        _PLATFORMS: str(attr.target_platform),
    }

_linkage_transition = transition(
    implementation = _linkage_transition_impl,
    inputs = [_LIBC],
    outputs = [_CXX_RUNTIME, _LIBC, _PLATFORMS],
)

def _linkage_binary_impl(ctx):
    binary = ctx.attr.binary[0][DefaultInfo]
    executable = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(
        output = executable,
        target_file = binary.files_to_run.executable,
        is_executable = True,
    )
    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = [executable]).merge(binary.default_runfiles),
    )]

linkage_binary = rule(
    implementation = _linkage_binary_impl,
    doc = "Builds a binary for the given platform and linkage preferences.",
    attrs = {
        "binary": attr.label(cfg = _linkage_transition, mandatory = True),
        "cxx_runtime_preference": attr.string_list(),
        "libc_preference": attr.string_list(),
        "target_platform": attr.label(mandatory = True),
    },
    executable = True,
)
