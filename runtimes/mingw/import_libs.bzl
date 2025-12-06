load("@bazel_lib//lib:run_binary.bzl", "run_binary")

def _sanitize_label(segment):
    result = []
    for idx in range(len(segment)):
        c = segment[idx:idx + 1].lower()
        if (("a" <= c) and (c <= "z")) or (("0" <= c) and (c <= "9")):
            result.append(c)
        else:
            result.append("_")
    value = "".join(result)
    if not value:
        fail("Cannot sanitize empty label segment")
    if ("0" <= value[0]) and (value[0] <= "9"):
        value = "_" + value
    return value

def _collect_definitions(preferred_dirs):
    mappings = {}
    for directory in preferred_dirs:
        for path in sorted(native.glob(["%s/*.def" % directory], allow_empty = True)):
            name = path.rsplit("/", 1)[1][:-4]
            key = _sanitize_label(name)
            if key not in mappings:
                mappings[key] = struct(
                    name = name,
                    src = path,
                )
    return mappings

def define_mingw_imports(name, dlltool_flags, directories):
    defs = _collect_definitions(directories)
    import_targets = []

    for key in sorted(defs.keys()):
        info = defs[key]
        out = "import-libs/{}/lib{}.a".format(name, info.name)
        target = "import_lib_{}_{}".format(name, key)
        run_binary(
            name = target,
            srcs = [info.src],
            outs = [out],
            tool = ":dlltool",
            args = dlltool_flags + [
                "-d",
                "$(location %s)" % info.src,
                "-l",
                "$@",
            ],
            visibility = ["//visibility:public"],
        )
        import_targets.append(":" + target)

    native.filegroup(
        name = "mingw_import_libraries_{}".format(name),
        srcs = import_targets,
        visibility = ["//visibility:public"],
    )
