default: serve

serve:
	mkdocs serve

here = $(shell pwd)

# https://www.mkdocs.org/user-guide/deploying-your-docs/
deploy:
	git commit -a -m "Deploying"
	git push
	cd ../DynamicTimeWarping.github.io && \
	mkdocs gh-deploy --force --config-file $(here)/mkdocs.yml --remote-branch master

deploy-nochange:
	cd ../DynamicTimeWarping.github.io && \
	mkdocs gh-deploy --force --config-file $(here)/mkdocs.yml --remote-branch master



pythumbs: docs/py-images/*.png
	cd docs/py-images && \
	for i in *.png; do convert -geometry x150 $$i thumbs/$$i; done

copyapi:
	make -C ../dtw-python docs
	-mkdir -p docs/py-api
	cp -a ../dtw-python/docs/_build/html docs/py-api
