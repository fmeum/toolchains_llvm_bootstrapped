load("@rules_testing//lib:analysis_test.bzl", "analysis_test")
load("@rules_testing//lib:truth.bzl", "matching")

_LIBC = str(Label("@platforms_contrib//os/linux/libc:preference"))
_CRT = str(Label("@platforms_contrib//os/windows/crt:preference"))
_CXX_RUNTIME = str(Label("@rules_cc//cc/cxx_runtime:preference"))

def _expect_failure(message):
    def impl(env, target):
        env.expect.that_target(target).failures().contains_predicate(matching.contains(message))

    return impl

def linkage_failure_test_suite(name, target, shared_library, dynamic_deps):
    """Declares tests for preferences that fail for a target, but not for the toolchain itself.

    Libc and CRT preferences that the toolchain can't deliver also fail for the libraries that the
    toolchain depends on, which Bazel reports as a toolchain resolution error even with
    --allow_analysis_failures. They are covered by the tests in rules_cc with a mock toolchain.

    Args:
      name: The name of the test suite.
      target: A cc_binary.
      shared_library: A cc_shared_library.
      dynamic_deps: A cc_binary with dynamic_deps.
    """
    tests = []
    for test, tested, platform, settings, message in [
        ("no_shared_runtime_for_static_libc", target, "//tests/linkage:linkage_test_linux_x86_64_no_libc", {_LIBC: ["static-musl"], _CXX_RUNTIME: ["bundled-libc++"]}, "a statically linked libc can't be combined with a shared C++ runtime"),
        ("no_shared_library_for_static_libc", shared_library, "//tests/linkage:linkage_test_linux_x86_64_no_libc", {_LIBC: ["static-musl"], _CXX_RUNTIME: ["static-libc++"]}, "can't be linked since"),
        ("no_cxx_runtime_for_no_libc", target, "//tests/linkage:linkage_test_linux_x86_64_no_libc", {_LIBC: ["none"], _CXX_RUNTIME: ["static-libc++"]}, "a C++ runtime can't be used without a libc"),
        ("no_dynamic_deps_for_no_libc", dynamic_deps, "//tests/linkage:linkage_test_linux_x86_64_no_libc", {_LIBC: ["none"]}, "can't depend on these shared libraries"),
        ("undeclared_system_runtime", target, "//tests/linkage:linkage_test_linux_x86_64_glibc", {_CXX_RUNTIME: ["libstdc++"]}, "doesn't declare libstdc++ as available"),
        ("wrong_runtime_flavor", target, "//tests/linkage:linkage_test_linux_x86_64_glibc", {_CXX_RUNTIME: ["static-libstdc++"]}, "doesn't define the feature 'libstdcxx_runtime'"),
        ("no_static_libcxx_on_macos", target, "//platforms:macos_aarch64", {_CXX_RUNTIME: ["static-libc++"]}, "doesn't define the feature 'static_cxx_runtime'"),
        ("no_bundled_libcxx_on_macos", target, "//platforms:macos_aarch64", {_CXX_RUNTIME: ["bundled-libc++"]}, "doesn't define the feature 'bundled_cxx_runtime'"),
        ("no_bundled_libcxx_on_mingw", target, "//platforms:windows_x86_64", {_CXX_RUNTIME: ["bundled-libc++"]}, "doesn't define the feature 'dynamic_cxx_runtime'"),
    ]:
        test_name = "{}_{}_test".format(name, test)
        analysis_test(
            name = test_name,
            target = tested,
            impl = _expect_failure(message),
            expect_failure = True,
            config_settings = {
                "//command_line_option:platforms": str(Label(platform)),
            } | settings,
        )
        tests.append(test_name)

    native.test_suite(name = name, tests = tests)
