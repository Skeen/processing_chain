# Download .tar files from server
#--------------------------------
ifeq ($(REMOTE_KNN),true)
$(KNN_DTW_NAME): $(JOBFILE_QRY) $(JOBFILE_REF)
	@mkdir -p output
	$(REMOTE_KNN_DTW_REQUEST) $(JOBFILE_REF) $(JOBFILE_QRY) "" $(REMOTE_KNN_SPLIT) $(REMOTE_KNN_TIMEOUT) > $@

$(KNN_DTW_TAR): $(KNN_DTW_NAME)
	@mkdir -p output
	cat $< | xargs $(REMOTE_KNN_DTW_RESPONSE) > $@
else
# .jobfiles to .json
$(KNN_DTW_TAR): $(JOBFILE_QRY) $(JOBFILE_REF)
	@mkdir -p output
	$(LOCAL_KNN_DTW) --query_filename=$(JOBFILE_QRY) --reference_filename=$(JOBFILE_REF) > $@
endif

ifeq ($(REMOTE_KNN),true)
$(KNN_DTW_MODEL_NAME): $(JOBFILE_COMBINED)
	@mkdir -p output
	$(REMOTE_KNN_DTW_REQUEST) $(JOBFILE_COMBINED) $(JOBFILE_COMBINED) "-m" $(REMOTE_KNN_SPLIT) $(REMOTE_KNN_TIMEOUT) > $@

$(KNN_DTW_MODEL_TAR): $(KNN_DTW_MODEL_NAME)
	@mkdir -p output
	cat $< | xargs $(REMOTE_KNN_DTW_RESPONSE) > $@
else
# .jobfiles to .json
$(KNN_DTW_MODEL_TAR): $(JOBFILE_COMBINED)
	@mkdir -p output
	$(LOCAL_KNN_DTW) --query_filename=$(JOBFILE_COMBINED) --reference_filename=$(JOBFILE_COMBINED) -m > $@
endif
