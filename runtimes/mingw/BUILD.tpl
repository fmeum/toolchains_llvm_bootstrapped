load("@toolchains_llvm_bootstrapped//toolchain:selects.bzl", "platform_llvm_binary")
load("@toolchains_llvm_bootstrapped//runtimes/mingw:import_libs.bzl", "define_mingw_imports")
load("@bazel_skylib//rules/directory:directory.bzl", "directory")
load("@bazel_skylib//rules/directory:subdirectory.bzl", "subdirectory")
load("@bazel_skylib//rules:expand_template.bzl", "expand_template")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

alias(
    name = "dlltool",
    actual = platform_llvm_binary("bin/llvm-dlltool"),
)

define_mingw_imports(
    name = "x86_64",
    dlltool_flags = [
        "-m",
        "i386:x86-64",
    ],
    directories = [
        "mingw-w64-crt/lib64",
        "mingw-w64-crt/lib-common",
    ],
)

define_mingw_imports(
    name = "aarch64",
    dlltool_flags = [
        "-m",
        "arm64",
    ],
    directories = [
        "mingw-w64-crt/libarm64",
        "mingw-w64-crt/lib-common",
    ],
)

filegroup(
    name = "mingw_headers",
    srcs = glob([
        "mingw-w64-headers/include/**",
        "mingw-w64-headers/crt/**",
        "mingw-w64-crt/include/**",
        "mingw-w64-crt/crt/**",
    ]) + [
        ":mingw_generated_mingw_header",
        ":mingw_generated_mingw_ddk_header",
    ],
    visibility = ["//visibility:public"],
)

expand_template(
    name = "mingw_generated_mingw_header",
    template = "mingw-w64-headers/crt/_mingw.h.in",
    substitutions = {
        "@DEFAULT_MSVCRT_VERSION@": "0xE00",
        "@DEFAULT_WIN32_WINNT@": "0xa00",
    },
    out = "mingw-w64-headers/crt/_mingw.h",
    visibility = ["//visibility:public"],
)

directory(
    name = "mingw_headers_directory",
    srcs = glob([
        "mingw-w64-headers/include/**",
        "mingw-w64-headers/crt/**",
        "mingw-w64-crt/include/**",
        "mingw-w64-crt/crt/**",
    ]),
    visibility = ["//visibility:public"],
)

subdirectory(
    name = "mingw_w64_crt_include_directory",
    parent = ":mingw_headers_directory",
    path = "mingw-w64-crt/include",
    visibility = ["//visibility:public"],
)

subdirectory(
    name = "mingw_w64_crt_crt_directory",
    parent = ":mingw_headers_directory",
    path = "mingw-w64-crt/crt",
    visibility = ["//visibility:public"],
)

subdirectory(
    name = "mingw_w64_headers_include_directory",
    parent = ":mingw_headers_directory",
    path = "mingw-w64-headers/include",
    visibility = ["//visibility:public"],
)

subdirectory(
    name = "mingw_w64_headers_crt_directory",
    parent = ":mingw_headers_directory",
    path = "mingw-w64-headers/crt",
    visibility = ["//visibility:public"],
)

write_file(
    name = "mingw_generated_mingw_ddk_header",
    out = "mingw-w64-headers/crt/sdks/_mingw_ddk.h",
    content = [
        "#ifndef _MINGW_DDK_H_",
        "#define _MINGW_DDK_H_",
        "",
        "#endif /* _MINGW_DDK_H_ */",
    ],
    visibility = ["//visibility:public"],
)

directory(
    name = "mingw_generated_headers_directory",
    srcs = [
        ":mingw_generated_mingw_header",
        ":mingw_generated_mingw_ddk_header",
    ],
    visibility = ["//visibility:public"],
)

subdirectory(
    name = "mingw_generated_headers_crt_directory",
    parent = ":mingw_generated_headers_directory",
    path = "mingw-w64-headers/crt",
    visibility = ["//visibility:public"],
)

directory(
    name = "mingw_import_libraries_directory",
    srcs = [
        ":mingw_import_libraries_x86_64",
        ":mingw_import_libraries_aarch64",
    ],
    visibility = ["//visibility:public"],
)

subdirectory(
    name = "mingw_import_libraries_x86_64_directory",
    parent = ":mingw_import_libraries_directory",
    path = "import-libs/x86_64",
    visibility = ["//visibility:public"],
)

subdirectory(
    name = "mingw_import_libraries_aarch64_directory",
    parent = ":mingw_import_libraries_directory",
    path = "import-libs/aarch64",
    visibility = ["//visibility:public"],
)
