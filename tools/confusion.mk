# Process our .tar file into .json (confusion)
#---------------------------------------------
include tools/confusion_helper.mk

#-------#
# Model #
#-------#
# Unpack tar file, and combine pieces into a single json
$(KNN_DTW_MODEL_JSON): $(KNN_DTW_MODEL_TAR)
	@mkdir -p $(dir $@)
	cd $(TMP_FOLDER) && tar -xzf $(shell realpath $<) --strip-components 1 
	cat $(TMP_FOLDER)/* | tr --delete '\n' | tr ',' '\n' | sed 's/\]\[/,/g' | tr '\n' ',' > $@

# Generate model
$(KNN_CONFUSION_MODEL_JSON): $(KNN_DTW_MODEL_JSON)
	@mkdir -p $(dir $@)
	cat $< | $(KNN_CONFUSION) --modelling > $@

#---------#
# Reading #
#---------#
ifeq ($(USE_SPLIT),true)
# Unpack our tar file, and create dummy file
$(KNN_DTW_JSONS): $(KNN_DTW_TAR)
	@rm -rf $(dir $@)
	@mkdir -p $(dir $@)
	cd $(dir $@) && tar -xzf $(shell realpath $<) --strip-components 1 
	echo "{}" > $@
else
# Unpack our tar file, and combine them
$(KNN_DTW_JSONS): $(KNN_DTW_TAR)
	@rm -rf $(dir $@)
	@mkdir -p $(dir $@)
	cd $(dir $@) && tar -xzf $(shell realpath $<) --strip-components 1 
	$(eval TMP_FILE=$(shell mktemp))
	cat $(dir $@)/* | tr --delete '\n' | tr ',' '\n' | sed 's/\]\[/,/g' | tr '\n' ',' > $(TMP_FILE)
	rm -rf $(dir $@)/*
	mv $(TMP_FILE) $@
endif

ifeq ($(USE_MODEL),true)
# Use sub-makefile to parallel process each file
$(KNN_CONFUSION_JSONS): $(KNN_DTW_JSONS) $(KNN_CONFUSION_MODEL_JSON) .flags/KNN_CONFUSION_ARGS .flags/USE_MODEL
	make -f Makefile_helper -j8
	echo "{}" > $@
else
# Use sub-makefile to parallel process each file
$(KNN_CONFUSION_JSONS): $(KNN_DTW_JSONS) .flags/KNN_CONFUSION_ARGS .flags/USE_MODEL
	make -f Makefile_helper -j8
	echo "{}" > $@
endif

# Combine confusion files
$(KNN_CONFUSION_JSON): $(KNN_CONFUSION_JSONS)
	@mkdir -p $(dir $@)
	$(KNN_COMBINER) $(shell realpath $(shell dirname $<)) > $@
