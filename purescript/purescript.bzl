"""Rules for purescript"""

run_template = """
#!/usr/bin/env bash
set -o errexit

node -e "require('./{target_path}/{entry_module}/index.js').{entry_function}({entry_params})"
"""

compile_trans_template = "cp -R {path}/* {output}"

def _purescript_compile(ctx):
    srcs = ctx.files.srcs + ctx.files.deps
    target = ctx.actions.declare_file(ctx.outputs.target.basename)
    purs = ctx.executable.purs

    cmd = "\n".join(
        [ "set -o errexit"
        , """mkdir "$2" """
        , """ "$1" compile --output "$2" "${@:3}" """
        ]
    )

    ctx.actions.run_shell(
        inputs = srcs + [purs],
        outputs = [target],
        command = cmd,
        arguments = [purs.path, target.path] +
                    [src.path for src in srcs if src.extension == "purs"],
    )

    return target

def _purescript_tar(ctx):
    target = _purescript_compile(ctx)
    tar = ctx.actions.declare_file(ctx.outputs.tar.basename)
    ctx.actions.run_shell(
        inputs = [target],
        outputs = [tar],
        command = """
            set -o errexit
            tar --create --file "$1" --directory "$2" .
        """,
        arguments = [tar.path, target.path],
    )

def _purescript_app(ctx):
    target = _purescript_compile(ctx)

    entry_params = ",".join([
        '\\"{entry}\\"'.format(entry=e) for e in ctx.attr.entry_parameters
    ])

    script = ctx.actions.declare_file(ctx.label.name)
    script_content = run_template.format(
        target_path    = target.short_path,
        entry_module   = getattr(ctx.attr, "entry_module"),
        entry_function = getattr(ctx.attr, "entry_function"),
        entry_params   = entry_params,
    )
    ctx.actions.write(script, script_content, is_executable = True)

    runfiles = ctx.runfiles(files = [target])

    return [DefaultInfo(executable = script, runfiles = runfiles)]

purescript_app = rule(
    implementation = _purescript_app,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
        ),
        "deps": attr.label_list(
            default = [],
        ),
        "purs": attr.label(
            allow_single_file = True,
            executable = True,
            cfg = "host",
            default = "@purs",
        ),
        "entry_module": attr.string(
            default = "Main",
        ),
        "entry_function": attr.string(
            default = "main",
        ),
        "entry_parameters": attr.string_list(
            default = [],
        ),
    },
    outputs = {
        "target": "target",
    },
    executable = True,
)

def _purescript_lib(ctx):
    _purescript_compile(ctx)

purescript_lib = rule(
    implementation = _purescript_lib,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
        ),
        "deps": attr.label_list(
            default = [],
        ),
        "purs": attr.label(
            allow_single_file = True,
            executable = True,
            cfg = "host",
            default = "@purs",
        ),
    },
    outputs = {
        #"tar": "%{name}.tar",
        "target": "target",
    },
)

test_template = """
err=0
node -e "require('./{target_path}/{test_file}/index.js').{entry_function}()" || err=1
echo
"""

def _run_test(target_path, entry_module, entry_function):
    return test_template.format(
        target_path = target_path,
        test_file = entry_module,
        entry_function = entry_function,
    )

def _purescript_test(ctx):
    target = _purescript_compile(ctx)

    script = "\n".join(
        ["""
#!/usr/bin/env bash
err=0
"""     , _run_test(target.short_path, ctx.attr.main_module, ctx.attr.main_function)
        , "exit $err"
        ],
    )
    ctx.actions.write(
        output = ctx.outputs.executable,
        content = script,
    )

    runfiles = ctx.runfiles(files = [target])
    return [DefaultInfo(runfiles = runfiles)]

purescript_test = rule(
    implementation = _purescript_test,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
        "main_module": attr.string(
            default = "Test.Main",
        ),
        "main_function": attr.string(
            default = "main",
        ),
        "purs": attr.label(
            allow_single_file = True,
            executable = True,
            cfg = "host",
            default = "@purs",
        ),
    },
    outputs = {
        "target": "test-target",
    },
    test = True,
)


_default_purs_pkg_url = \
    "https://github.com/purescript/purescript/releases/download/v0.12.0/linux64.tar.gz"
_default_purs_pkg_sha256 = \
    "ccd777d9350c2e238d5be26419d3f54e2a335940b82c0baed040698c7cb1c7f1"
_default_purs_pkg_strip_prefix = \
    "purescript"

def purescript_toolchain(url=_default_purs_pkg_url, sha256=_default_purs_pkg_sha256, strip_prefix=_default_purs_pkg_strip_prefix):
    native.new_http_archive(
        name = "purs",
        urls = [url],
        sha256 = sha256,
        strip_prefix = strip_prefix,
        build_file_content = """exports_files(["purs"])""",
    )

_purescript_dep_build_content = """
filegroup(
    name = "pkg",
    srcs = glob(["src/**/*.purs", "src/**/*.js"]),
    visibility = ["//visibility:public"],
)
"""

def purescript_dep(name, url, sha256, strip_prefix):
    native.new_http_archive(
        name               = name,
        urls               = [url],
        sha256             = sha256,
        strip_prefix       = strip_prefix,
        build_file_content = _purescript_dep_build_content,
    )
