Purescript Rules for Bazel
==========================

Adding purescript support to your bazel repo
--------------------------------------------
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
load("@io_bazel_rules_purescript//purescript:purescript.bzl", "purescript_toolchain", "purescript_dep")

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

Defining a project
------------------
With this in place you can now define a `BUILD` file for your project:

```python
load("@io_bazel_rules_purescript//purescript:purescript.bzl", "purescript_app", "purescript_test")

dependencies = \
    [ "@purescript_console//:pkg"
    , "@purescript_effect//:pkg"
    , "@purescript_prelude//:pkg"
    ]

# Defines an application with default entrypoint (Main.main):
purescript_app(
    name       = "purs-app",
    visibility = ["//visibility:public"],
    srcs       = glob(["src/**/*.purs"]),
    deps       = dependencies,
)
```

You can now build your program and run the main function!

If you want to customize the entrypoint, you can do something like:

```python
purescript_app(
    name             = "purs-app",
    visibility       = ["//visibility:public"],
    srcs             = glob(["src/**/*.purs"]),
    deps             = dependencies,
    entry_module     = "MyModule",
    entry_function   = "myFunction",
    entry_parameters = [ "my", "parameters" ],
)
```

Testing
-------
In the same `BUILD` file, you can define a test module:
```python
purescript_test(
    name = "purs-app-test",
    srcs = glob(["test/**/*.purs"]) + glob(["src/**/*.purs"]),
    deps = dependencies,
)
```

in the `test` directory I've created a module like:

```purescript
module Test.Main where

-- imports omitted

main :: Effect Unit
main = log "Hello test world!"
```

when you run `bazel test` on the `:purs-app-test` project, it should succeed
:tada:

**NOTE:** the default entrypoint for testing is the module `Test.Main` and the
function `main`. But these can be overwritten:

```python
purescript_test(
    name          = "purs-app-test",
    srcs          = glob(["test/**/*.purs"]) + glob(["src/**/*.purs"]),
    deps          = dependencies,
    main_module   = "MyMainTest.Whatever"
    main_function = "myFun"
)
```

TODO
====
- [ ] Make sure that dependencies between projects in monorepo work

  This relies on separate compilation being a thing in Purescript, otherwise
  each project is going to need to expose its sources to other projects
  somehow.

- [ ] Add unit testing and `.travis.yml` to the repo
