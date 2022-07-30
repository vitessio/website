HUGO?=npx hugo
DEPLOY_PRIME_URL?=/

production-build:
	$(HUGO) --cleanDestinationDir \
	--minify \
	--verbose

preview-build:
	$(HUGO) --cleanDestinationDir \
	--buildDrafts \
	--buildFuture \
	--baseURL $(DEPLOY_PRIME_URL) \
	--minify

serve:
	$(HUGO) server \
	--buildDrafts \
	--buildFuture \
	--ignoreCache \
	--disableFastRender \
	--verbose

clean:
	rm -rf public

build:
	$(HUGO) --cleanDestinationDir -e dev -DFE

link-checker-setup:
	curl https://raw.githubusercontent.com/wjdp/htmltest/master/godownloader.sh | bash

run-link-checker:
	bin/htmltest

check-internal-links: clean build link-checker-setup run-link-checker

check-all-links: clean build link-checker-setup
	bin/htmltest --conf .htmltest.external.yml
