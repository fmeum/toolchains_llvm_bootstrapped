load("@with_cfg.bzl", "with_cfg")
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")

ubsan_cc_binary, _ubsan_cc_binary_internal = with_cfg(cc_binary).set(
    Label("@toolchains_llvm_bootstrapped//config:ubsan"), True
).build()

mingw_cc_binary, _mingw_cc_binary_internal = with_cfg(cc_binary).set(
    "platforms",
    [Label("@toolchains_llvm_bootstrapped//platforms:windows_x86_64")],
).build()

mingw_arm64_cc_binary, _mingw_arm64_cc_binary_internal = with_cfg(cc_binary).set(
    "platforms",
    [Label("@toolchains_llvm_bootstrapped//platforms:windows_aarch64")],
).build()
