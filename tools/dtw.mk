# Download .tar files from server
#--------------------------------
# TODO: Combine these into one rule
ifeq ($(REMOTE_KNN),true)
$(KNN_DTW_NAME): $(JOBFILE_QRY) $(JOBFILE_REF)
	@mkdir -p $(dir $@)
	$(REMOTE_KNN_DTW_REQUEST) $(JOBFILE_REF) $(JOBFILE_QRY) "" $(REMOTE_KNN_SPLIT) $(REMOTE_KNN_TIMEOUT) > $@

$(KNN_DTW_TAR).download: $(KNN_DTW_NAME)
	@mkdir -p $(dir $@)
	cat $< | xargs $(REMOTE_KNN_DTW_RESPONSE) > $@

$(KNN_DTW_TAR).md5: $(KNN_DTW_TAR).download
	@mkdir -p $(dir $@)
	md5sum $< | cut -f1 -d' ' | tr --delete '\n' > $@

$(KNN_DTW_TAR): $(KNN_DTW_TAR).download $(KNN_DTW_TAR).md5 $(KNN_DTW_NAME)
	@mkdir -p $(dir $@)
	@if [ "$(shell cat $(KNN_DTW_NAME) | xargs $(REMOTE_KNN_DTW_MD5))" = "$(shell cat $(KNN_DTW_TAR).md5)" ]; then \
		echo "MD5 check passed: '$@'"; \
		cp $(KNN_DTW_TAR).download $@; \
	else \
		echo "MD5 check failed: '$@', removing $<"; \
		rm $(KNN_DTW_TAR).download $(KNN_DTW_TAR).md5; \
		false; \
	fi
else
# .jobfiles to .json
$(KNN_DTW_TAR).source: $(JOBFILE_QRY) $(JOBFILE_REF)
	@mkdir -p $(dir $@)
	$(LOCAL_KNN_DTW) --query_filename=$(JOBFILE_QRY) --reference_filename=$(JOBFILE_REF) > $@

# .json to tar
$(KNN_DTW_TAR): $(KNN_DTW_TAR).source
	tar -czvf $@ -C $(dir $<) $(notdir $<)
endif

ifeq ($(REMOTE_KNN),true)
$(KNN_DTW_MODEL_NAME): $(JOBFILE_COMBINED)
	@mkdir -p $(dir $@)
	$(REMOTE_KNN_DTW_REQUEST) $(JOBFILE_COMBINED) $(JOBFILE_COMBINED) "-m" $(REMOTE_KNN_SPLIT) $(REMOTE_KNN_TIMEOUT) > $@

$(KNN_DTW_MODEL_TAR).download: $(KNN_DTW_MODEL_NAME)
	@mkdir -p $(dir $@)
	cat $< | xargs $(REMOTE_KNN_DTW_RESPONSE) > $@

$(KNN_DTW_MODEL_TAR).md5: $(KNN_DTW_MODEL_TAR).download
	@mkdir -p $(dir $@)
	md5sum $< | cut -f1 -d' ' | tr --delete '\n' > $@

$(KNN_DTW_MODEL_TAR): $(KNN_DTW_MODEL_TAR).download $(KNN_DTW_MODEL_TAR).md5 $(KNN_DTW_MODEL_NAME)
	@mkdir -p $(dir $@)
	@if [ "$(shell cat $(KNN_DTW_MODEL_NAME) | xargs $(REMOTE_KNN_DTW_MD5))" = "$(shell cat $(KNN_DTW_MODEL_TAR).md5)" ]; then \
		echo "MD5 check passed: '$@'"; \
		cp $(KNN_DTW_MODEL_TAR).download $@; \
	else \
		echo "MD5 check failed: '$@', removing $<"; \
		rm $(KNN_DTW_MODEL_TAR).download $(KNN_DTW_MODEL_TAR).md5; \
		false; \
	fi
else
# .jobfiles to .json
$(KNN_DTW_MODEL_TAR).source: $(JOBFILE_COMBINED)
	@mkdir -p $(dir $@)
	$(LOCAL_KNN_DTW) --query_filename=$(JOBFILE_COMBINED) --reference_filename=$(JOBFILE_COMBINED) -m > $@

# .json to tar
$(KNN_DTW_MODEL_TAR): $(KNN_DTW_MODEL_TAR).source
	tar -czvf $@ -C $(dir $<) $(notdir $<)
endif
