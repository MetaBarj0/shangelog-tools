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

Go into the `test` directory and execute the `run-all-tests.sh` scripts. You'll
need docker for this. The test suite is also designed to be run within a CI/CD
pipeline. It is fully automated. The exit code is 0 if all test pass or a non
zero integer otherwise. By default, all tests are run in parallel because there
are fully independent from each other.

### Test runner modes

You can pass an additional argument to the `run-all-tests.sh` script to control
its behavior.

#### the `-d` or `--debug` option

This option forces each test to be run serially. It's especially useful when
contributing or debugging a test suite because it allows each test to be paused
thanks to the `pause_test` function. Thus you can go straight into the docker
test container, cd into the directory that is reported in the console by the
`pause_test` function and start spelunking.
Note that you cannot pass both `-d` and `-w` at the same time. Those arguments
are mutually exclusive.

#### the '-w' or `--watch` option

This option allow test suites to be run each time a relevant file is modified.
It's very useful while contributing and greatly add to your productivity.
Coupled with the ability of bats to [focus on specific
tests](https://bats-core.readthedocs.io/en/stable/writing-tests.html#special-tags)
it's a real game changer. I suggest you to mainly use this option while
developing.
Note that you cannot pass both `-w` and `-d` at the same time. Those arguments
are mutually exclusive.

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
handle any update of them as you'll lose the git repository.
