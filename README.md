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

Integrate this repository in the one you want to generate the `CHANGELOG.md` for as a submodule.
Configure the thing and invoke the tool. That's it.

# WHEN

Each time you want to release, that is, as often as possible.
