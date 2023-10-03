#!/bin/bash

set -exuo pipefail

persist_tmpdir=${COBRADOCS_SYNC_PERSIST:-}
tmp="vitessio.website"

if [[ -z "${persist_tmpdir}" ]]; then
    trap "rm -rf ${tmp}" EXIT
fi

if [ ! -d "${tmp}" ]; then
    tmp="$(mktemp -d vitessio.website)"

    git clone --depth=1 git@github.com:vitessio/vitess "${tmp}/vitess" && \
        cd "${tmp}/vitess" && \
        git fetch --tags && \
        cd -
fi

VITESS_DIR="$(pwd)/${tmp}/vitess" make generated-docs

git add $(git diff -I"^commit:.*$" --numstat | awk '{print $3}' | xargs)
# Reset any modified files that contained _only_ a SHA update.
git checkout -- .
# Add any net-new files that were missed in the first `git add`.
git add content/**
git commit -sm "sync cobradocs to latest release branches"
