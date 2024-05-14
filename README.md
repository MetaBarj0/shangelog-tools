# WHAT

A collection of tools to manipulate changelog files and handle a git repository
with care using the conventional commit convention and SemVer versioning.

## Generating changelogs

`generate.sh` can automatically produce a changelog regarding your repository
content if you use the conventional commits convention.

## Package tools

`package-generate.sh` produce a single script you can install everywhere on
your environment. It eases the usage of this tool not forcing you to clone this
repository to use it.

# WHO

## Generating changelogs

Any project developer, maintainer, ops.
Also designed to be used within a pipeline managed by your CI/CD
infrastructure.

## Package tools

Any developer who want to use these tools on at least one repository. Also
designed to be used within a pipeline managed by your CI/CD infrastructure
though in this case, cloning the repository is ok in a first place.

# WHY

## Generating changelogs

Because creating, amending, maintaining, fixing `CHANGELOG.md` file by hand is
tedious, error prone and we've better things to do.
Moreover, in some cases, it could be really complicated if not impossible
(rebase scenarii for instance, bacause of commit sha1 changes).

## Package tools

To control the system wide installation and access of these tools without being
forced to clone this repository or use this repository as submodule for each
repository you want to track.

# HOW

## Generating changelogs

Invoke the `generate.sh` script for a given repository. See the `--help` or
`-h` option to see usage information.

## Run all tests of this repository

Go into the `test` directory and execute the `run-all-tests.sh` scripts.
You'll need docker for this. The test suite is also designed to be runb within
a CI/CD pipeline. it is fully automated. The exit code is 0 if all test pass or
a non zero integer otherwise.

### Debugging

Alternatively, you can pass any argument to the `run-all-tests.sh` script to
disable parallel test execution and debug a specific test using the
`pause_test` in any test case, should you need to do it.
The test suite run into a docker container that is automatically deleted when
the test suite ends its execution.
`pause_test` allow a test to be paused (just like a breakpoint) thus, allowing
the underlying container to live while the test is paused.
Just run a `bash` in this container, `cd` into the test directory (given by the
`pause_test` function) and start debug at your heart content.

## Package tools

### TODO

Run the `package-generate.sh` script to produce a single script you can install
everywhere. Use the `--help` option to get usage information.

# WHEN

## Generating changelogs

- Each time you want to release, that is, as often as possible, ideally in a
  CI/CD environment.
- After a rebase, when commit sha have changed.

## Package tools

As you wish, it's not mandatory. You can use the full feature set of these
tools directly in this repository. Packaging tools maybe an interesting option
if you want them system wide. Keep in mind however you'll have to manually
handle any update of them.
