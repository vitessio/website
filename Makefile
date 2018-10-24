production-build:
	hugo

preview-build:
	hugo \
	--buildDrafts \
	--buildFuture \
	--baseURL $(DEPLOY_PRIME_URL)

serve:
	hugo server \
	--buildDrafts \
	--buildFuture \
	--disableFastRender