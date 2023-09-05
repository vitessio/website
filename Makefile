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

ifndef VTCTLDCLIENT_VERSION_PAIRS
export VTCTLDCLIENT_VERSION_PAIRS="main:16.0,v15.0.2:15.0"
endif

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make vtctldclient-docs
vtctldclient-docs:
	go run ./tools/vtctldclientdocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${VTCTLDCLIENT_VERSION_PAIRS}" vtctldclient
