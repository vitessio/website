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
export COBRADOC_VERSION_PAIRS="main:20.0,v19.0.1:19.0,v18.0.3:18.0,v17.0.6:17.0"
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

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make mysqlctl-docs
mysqlctl-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" mysqlctl

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make mysqlctld-docs
mysqlctld-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" mysqlctld

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make vtaclcheck-docs
vtaclcheck-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" vtaclcheck

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make topo2topo-docs
topo2topo-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" topo2topo

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make vtbackup-docs
vtbackup-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" vtbackup

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make vtbench-docs
vtbench-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" vtbench

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make vtclient-docs
vtclient-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" vtclient

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make vtcombo-docs
vtcombo-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" vtcombo

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make vtctld-docs
vtctld-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" vtctld

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make vtctldclient-docs
vtctldclient-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" vtctldclient

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make vtgate-docs
vtgate-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" vtgate

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make vtgateclienttest-docs
vtgateclienttest-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" vtgateclienttest

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make vtorc-docs
vtorc-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" vtorc

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make vttablet-docs
vttablet-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" vttablet

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make vttestserver-docs
vttestserver-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" vttestserver

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make vttlstest-docs
vttlstest-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" vttlstest

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make zk-docs
zk-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" zk

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make zkctl-docs
zkctl-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" zkctl

# Usage: VITESS_DIR=/full/path/to/vitess.io/vitess make zkctld-docs
zkctld-docs:
	go run ./tools/cobradocs/ --vitess-dir "${VITESS_DIR}" --version-pairs "${COBRADOC_VERSION_PAIRS}" zkctld
