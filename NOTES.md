# Random notes to delete

## List revision, header filtering

`git rev-list --all -E -i --grep '^(feat|fix|chore|build|ci|test|docs|style|refactor|perf|revert)(\(.+\))?!?: [^ ].*'`

## Major changing

### In the Header

If the type is suffixed with an exclamation mark: `!`.

### In the Footer

If any line in the very last paragraph are either:

- `BREAKING CHANGE: [^ ].*`
- `BREAKING-CHANGE: [^ ].*`

## Minor changing

If header type is `feat`

## Patch changing

If header type is `fix`

## Trailers

Decided not to handle these at first except for [Major Changing](# Major Changing)

## Listing relevant commits

### Scenarii

#### No tag at all in the repository

- `git describe` returns an error
- All commits must be selected
- filter all commits that are conventional ones
- Alert if there are non conventional commits

#### There are at least one tag, but not annotated

Same actions as [No tag at all in the repository](#### No tag at all in the repository)
Besides, alert on tag found that are not annotated.

#### There are at least one annotated tag not at the tip of the branch

- Ensure latest annotated tag exists:
  - `git describe --abbrev=0` does not return an error but the latest annotated
    tag
- List all commits from that annotated tag, excluding it, in reverse order:
  `git rev-list --reverse HEAD ^$(git describe --abbrev=0)`
- filter all commits that are conventional ones
- Alert if there are non conventional commits

### Extract summary info from conventional commit

- Extract the type, the scope and the description:
  `git show -s --pretty=format:%s <sha1>`

## Generating the CHANGELOG.md file

- Stateless by design:
  - regenerate the file each time the tool is used
  - implies to scan the entire repo (that should not be an issue)
  - lots of advantages with this approach:
    - Testable
    - insensitive to commit sha1 changes (rebases)
    - Easily Fixable
    - Easier to reason about
- stdout output
  - Redirect to a file
  - pipe in another process

### Structure of the CHANGELOG.md file

- A markdown Document.
    - Principal header (`#`) used for the SemVer annotated tag
      - Add the date (in the commit, not the actual date)
    - Next header (`##`) for Breaking changes, Fixes and Patches.
    - List content for each type of commit.
    - Specify the commit sha1 and the header.

## Compute version number (SemVer)

Look for, in that order:

- Major changes
  Nullify any Minor change
- Minor changes
  Nullify any Patch change
- Patch changes

If none of this type is found in commit list (for instance, there is only non
breacking chore), errors by default. However, an option can be specified to
always bump version in that case.

## Create annotated tags

After having redacted the CHANGELOG.md file.

# Testing the thing

[This project](https://github.com/bats-core/bats-core) looks promising.


