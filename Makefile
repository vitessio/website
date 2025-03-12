HUGO?=npx hugo
DEPLOY_PRIME_URL?=/

production-build: install
	$(HUGO) --cleanDestinationDir \
	--minify \
	--verbose

preview-build: install
	$(HUGO) --cleanDestinationDir -e dev \
	--buildDrafts \
	--buildFuture \
	--baseURL $(DEPLOY_PRIME_URL) \
	--minify

serve: install
	$(HUGO) server \
	--buildDrafts \
	--buildFuture \
	--ignoreCache \
	--disableFastRender \
	--verbose

install:
	npm install

clean:
	rm -rf public

build: install
	$(HUGO) --cleanDestinationDir -e dev -DFE

link-checker-setup:
	curl https://raw.githubusercontent.com/wjdp/htmltest/master/godownloader.sh | bash

run-link-checker:
	bin/htmltest

check-internal-links: clean build link-checker-setup run-link-checker

check-all-links: clean build link-checker-setup
	bin/htmltest --conf .htmltest.external.yml

ifndef COBRADOC_VERSION_PAIRS
export COBRADOC_VERSION_PAIRS="main:22.0,v21.0.3:21.0,v20.0.6:20.0"
endif

BINS := mysqlctl mysqlctld vtaclcheck topo2topo vtbackup vtclient vtcombo \
        vtctld vtctldclient vtgate vtgateclienttest vtorc vttablet vttestserver \
        vttlstest zk zkctl zkctld

# Pattern rule for building docs for a single binary.
# Running `make mysqlctl-docs` will trigger this rule, for example.
# VITESS_DIR should be specified as an environment variable, pointing to the root of the local Vitess repository
# with most recent code and all release branches fetched, for which the docs are being generated.
# Example, to make all current release  versions:
# `make mysqlctl-docs VITESS_DIR=~/go/src/github.com/vitessio/vitess`
# For a specific version, you can specify COBRADOC_VERSION_PAIRS as an environment variable, Example:
# `make mysqlctl-docs COBRADOC_VERSION_PAIRS="main:22.0" VITESS_DIR=~/go/src/github.com/vitessio/vitess`
%-docs:
	set -x
	@if echo "$$COBRADOC_VERSION_PAIRS" | grep -qE '20\.0'; then \
    		if [[ "$${GOROOT##*/}" != *go1.21* ]]; then \
    			echo "Error: Go 1.21 is required when COBRADOC_VERSION_PAIRS contains 20.0."; \
    			echo "Current GOROOT is: $$GOROOT"; \
    			exit 1; \
    		fi; \
    fi
	go run ./tools/cobradocs/  --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" $(patsubst %-docs,%,$@)
	COMMIT_HASH=$(shell cd $(VITESS_DIR) && git rev-parse --short HEAD); \
    	git add -u content && \
    	if ! git diff --cached --quiet HEAD --; then \
    	  git commit -s -m "Update cobradocs for $$COMMIT_HASH for $(patsubst %-docs,%,$@)"; \
    	fi

# Target to run them all.
.PHONY: generated-docs
generated-docs: $(BINS:%=%-docs)
