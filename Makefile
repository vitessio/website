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
export COBRADOC_VERSION_PAIRS="main:20.0,v19.0.3:19.0,v18.0.4:18.0"
endif

generated-docs: mysqlctl-docs \
	mysqlctld-docs \
	topo2topo-docs \
	vtaclcheck-docs \
	vtbackup-docs \
	vtbench-docs \
	vtclient-docs \
	vtcombo-docs \
	vtctld-docs \
	vtctldclient-docs \
	vtgate-docs \
	vtgateclienttest-docs \
	vtorc-docs \
	vttablet-docs \
	vttestserver-docs \
	vttlstest-docs \
	zk-docs \
	zkctl-docs \
	zkctld-docs


%-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" $*

.PHONY: generated-docs

