#!/bin/bash

set -exuo pipefail

persist_tmpdir=${COBRADOCS_SYNC_PERSIST:-}
tmp=${VITESS_DIR:-"$(pwd)/vitessio.website"}

#if [[ -z "${persist_tmpdir}" ]]; then
#    trap "rm -rf ${tmp}" EXIT
#fi

if [ ! -d "${tmp}" ]; then
    tmp="$(mktemp -d $tmp)"

    git clone --depth=1 git@github.com:vitessio/vitess "${tmp}" && \
        cd "${tmp}" && \
        git fetch --tags && \
        cd -
fi

VITESS_DIR="${tmp}" make generated-docs

git add $(git diff -I"^commit:.*$" --numstat | awk '{print $3}' | xargs) || true
# Reset any modified files that contained _only_ a SHA update.
git checkout -- .
# Add any net-new files that were missed in the first `git add`.
git add content/**

if [ $(git diff --cached --name-only | wc -l) -eq 0 ]; then
    echo "No changes to cobradocs detected" >&2
    exit 1
fi

git commit -sm "sync cobradocs to latest release branches"
