# Downloading
#------------
download/%.download:
	@mkdir -p $(dir $@)
	curl --fail --silent -o $@ http://skeen.website:3001/symlinks/$(INPUT_REGEX)/$(@F:.download= )

download/%.md5: download/%.download
	@mkdir -p $(dir $@)
	md5sum $< | cut -f1 -d' ' | tr --delete '\n' > $@

data/%: download/%.download download/%.md5
	@mkdir -p $(dir $@)
	@if [ "$(shell curl --fail --silent http://skeen.website:3001/md5/$(INPUT_REGEX)/$(@F))" = "$(shell cat download/$(@F).md5)" ]; then \
		echo "MD5 check passed: '$@'"; \
		cp $< $@; \
	else \
		echo "MD5 check failed: '$@', removing $<"; \
		rm download/$(@F).download download/$(@F).md5; \
		false; \
	fi
