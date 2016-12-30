# Download .tar files from server
#--------------------------------
# TODO: Combine these into one rule
ifeq ($(REMOTE_KNN),true)
$(KNN_DTW_NAME): $(JOBFILE_QRY) $(JOBFILE_REF)
	@mkdir -p $(dir $@)
	$(REMOTE_KNN_DTW_REQUEST) $(JOBFILE_REF) $(JOBFILE_QRY) "" $(REMOTE_KNN_SPLIT) $(REMOTE_KNN_TIMEOUT) > $@

$(KNN_DTW_TAR): $(KNN_DTW_NAME)
	@mkdir -p $(dir $@)
	cat $< | xargs $(REMOTE_KNN_DTW_RESPONSE) > $@
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

$(KNN_DTW_MODEL_TAR): $(KNN_DTW_MODEL_NAME)
	@mkdir -p $(dir $@)
	cat $< | xargs $(REMOTE_KNN_DTW_RESPONSE) > $@
else
# .jobfiles to .json
$(KNN_DTW_MODEL_TAR).source: $(JOBFILE_COMBINED)
	@mkdir -p $(dir $@)
	$(LOCAL_KNN_DTW) --query_filename=$(JOBFILE_COMBINED) --reference_filename=$(JOBFILE_COMBINED) -m > $@

# .json to tar
$(KNN_DTW_MODEL_TAR): $(KNN_DTW_MODEL_TAR).source
	tar -czvf $@ -C $(dir $<) $(notdir $<)
endif
