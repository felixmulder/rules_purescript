Purescript Rules for Bazel
==========================
*NOTE:* currently the instructions below don't work as expected, I'm trying to
sort it out, for now you can copy the `purescript.bzl` file to your `./tools/`
directory and ignore the `http_archive` directive. Replace all occurrences of
`@io_bazel_rules_purescript//:purescript.bzl` with `//tools:purescript.bzl`

This repo is the beginnings of support for purescript in Bazel. In order to use
this put the following into your `WORKSPACE` file:

```python
# refer to a githash in this repo:
rules_purescript_version = "e8ee09f60816875e006150600f457776af61399b"

# download the archive:
http_archive(
    name = "io_bazel_rules_purescript",
    url  = "https://github.com/felixmulder/rules_purescript/archive/%s.zip" % rules_purescript_version,
    type = "zip",
    strip_prefix = "rules_purescript-%s" % rules_purescript_version,
)

# load the purescript rules and functions:
load("@io_bazel_rules_purescript//:purescript.bzl", "purescript_toolchain", "purescript_dep")

# downloads the `purs` command:
purescript_toolchain()

# add some dependencies:
purescript_dep(
    name = "purescript_console",
    url = "https://github.com/purescript/purescript-console/archive/v4.1.0.tar.gz",
    sha256 = "5b0d2089e14a3611caf9d397e9dd825fc5c8f39b049d19448c9dbbe7a1b595bf",
    strip_prefix = "purescript-console-4.1.0",
)

purescript_dep(
    name = "purescript_effect",
    url = "https://github.com/purescript/purescript-effect/archive/v2.0.0.tar.gz",
    sha256 = "5254c048102a6f4360a77096c6162722c4c4b2449983f26058d75d4e5be9d301",
    strip_prefix = "purescript-effect-2.0.0",
)

purescript_dep(
    name = "purescript_prelude",
    url = "https://github.com/purescript/purescript-prelude/archive/v4.0.1.tar.gz",
    sha256 = "3b69b111875eb2b915fd7bdf320707ed3d22194d71cd51d25695d22ab06ae6ee",
    strip_prefix = "purescript-prelude-4.0.1",
)
```

With this in place you can now define a `BUILD` file for your project:

```python
load("@io_bazel_rules_purescript//:purescript.bzl", "purescript_app", "purescript_test")

# Defines an application with default entrypoint (Main.main):
purescript_app(
    name = "purs-app",
    srcs = glob(["src/**/*.purs"]),
    deps = [ "@purescript_console//:pkg"
           , "@purescript_effect//:pkg"
           , "@purescript_prelude//:pkg"
           ],
    visibility = ["//visibility:public"],
)
```

You can now build your program and run the main function!

TODO
====
- [ ] Fix repo structure so that commands above work as expected
- [ ] Transitive dependencies in `purescript_test` rule
- [ ] Make sure that dependencies between projects in monorepo work
- [ ] Add unit testing and `.travis.yml` to the repo
