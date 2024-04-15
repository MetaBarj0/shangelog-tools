# WHAT

A tool to automatically generate `CHANGELOG.md` files for your project tracked
in a `git` repository.
`shangelog tools`

# WHO

Any project developer, maintainer, ops.

# WHY

Because creating, amending, maintaining, fixing `CHANGELOG.md` file by hand is
tedious, error prone and we've better things to do.
Moreover, in some cases, it could be really complicated if not impossible
(rebase scenarii for instance, bacause of commit sha1 changes).

# HOW

## To generate a CHANGELOG.md file

You can either:
- Integrate this repository in the one you want to generate the `CHANGELOG.md`
  for as a submodule.
- Keep this repository separated from the one you want to generate the
  `CHANGELOG.md` file and use its tool

## Run all tests of this repository

Go into the `test` directory and execute the `run-all-tests.sh` scripts.
You'll need docker for this.

# WHEN

Each time you want to release, that is, as often as possible.
