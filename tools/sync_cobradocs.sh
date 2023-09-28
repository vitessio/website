#!/bin/bash

set -exuo pipefail

tmp="$(mktemp -d vitessio.website)"
trap "rm -rf ${tmp}" EXIT

git clone --depth=1 git@github.com:vitessio/vitess "${tmp}/vitess" && \
    cd "${tmp}/vitess" && \
    git fetch --tags && \
    cd -

VITESS_DIR="$(pwd)/${tmp}/vitess" make generated-docs
rm -rf "${tmp}/vitess"

git add $(git diff -I"^commit:.*$" --numstat | awk '{print $3}' | xargs)
# Reset any modified files that contained _only_ a SHA update.
git checkout -- .
# Add any net-new files that were missed in the first `git add`.
git add .
git commit -sm "sync cobradocs to latest release branches"
