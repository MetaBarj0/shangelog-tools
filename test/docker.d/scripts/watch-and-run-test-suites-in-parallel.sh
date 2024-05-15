#!/bin/sh

bats() {
  echo test/bats/bin/bats
}

$(bats) --formatter tap --jobs $(nproc) test/generate \
&& echo $'\n  ALL TESTS OF GENERATE SUITE PASSED!'

echo $'\n  Watching file system changes... CTRL+C to exit.'

