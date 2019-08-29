default: serve

serve:
	mkdocs serve

here = $(shell pwd)

# https://www.mkdocs.org/user-guide/deploying-your-docs/
deploy:
	cd ../DynamicTimeWarping.github.io && \
	mkdocs gh-deploy --config-file $(here)/mkdocs.yml --remote-branch master

