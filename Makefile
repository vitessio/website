production-build:
	hugo \
	--minify \
	--verbose

preview-build:
	hugo \
	--buildDrafts \
	--buildFuture \
	--baseURL $(DEPLOY_PRIME_URL) \
	--minify

serve:
	hugo server \
	--buildDrafts \
	--buildFuture \
	--ignoreCache \
	--disableFastRender \
	--verbose
