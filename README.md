# WHAT

A tool to automatically generate `CHANGELOG.md` files for your project tracked
in a `git` repository.

# WHO

Any project developer, maintainer, ops.
Also designed to be used within a pipeline managed by your CI/CD
infrastructure.

# WHY

Because creating, amending, maintaining, fixing `CHANGELOG.md` file by hand is
tedious, error prone and we've better things to do.
Moreover, in some cases, it could be really complicated if not impossible
(rebase scenarii for instance, bacause of commit sha1 changes).

# HOW

## Package the tool

### TODO

Run the `package-generate.sh` script to produce a single script you can install
everywhere. Use the `--help` option to get usage information.

## To generate a CHANGELOG.md file

You can either:
- Integrate this repository in the one you want to generate the `CHANGELOG.md`
  for as a submodule.
- Keep this repository separated from the one you want to generate the
  `CHANGELOG.md` file for.
- Install the script produced by `package-generate.sh` wherever you want to have either
  a system wide or a user wide installation.

## Run all tests of this repository

Go into the `test` directory and execute the `run-all-tests.sh` scripts.
You'll need docker for this.

# WHEN

Each time you want to release, that is, as often as possible.
