# Process our .tar file into .json (confusion)
#---------------------------------------------
include tools/confusion_helper.mk

#-------#
# Model #
#-------#
# Unpack tar file, and combine pieces into a single json
$(KNN_DTW_MODEL_UNTAR_LOCK): $(KNN_DTW_MODEL_TAR)
	@mkdir -p $(KNN_DTW_MODEL_UNTAR)
	cd $(KNN_DTW_MODEL_UNTAR) && tar -xzf $(shell realpath $<) --strip-components 1 
	touch $@

$(KNN_DTW_MODEL_JSON): $(KNN_DTW_MODEL_UNTAR_LOCK)
	@mkdir -p $(dir $@)
	cat $(KNN_DTW_MODEL_UNTAR)/* | tr --delete '\n' | tr ',' '\n' | sed 's/\]\[/,/g' | tr '\n' ',' > $@

# Generate model
$(KNN_CONFUSION_MODEL_JSON): $(KNN_DTW_MODEL_JSON)
	@mkdir -p $(dir $@)
	cat $< | $(KNN_CONFUSION) --modelling > $@

#---------#
# Reading #
#---------#
ifeq ($(USE_SPLIT),true)
# Unpack our tar file, and create dummy file
$(KNN_DTW_UNTAR_LOCK): $(KNN_DTW_TAR) .flags/USE_SPLIT
	@rm -rf $(KNN_DTW_UNTAR)
	@mkdir -p $(KNN_DTW_UNTAR)
	cd $(KNN_DTW_UNTAR) && tar -xzf $(shell realpath $<) --strip-components 1 
	touch $@
else
# Unpack our tar file, and combine them
$(KNN_DTW_UNTAR_LOCK): $(KNN_DTW_TAR) .flags/USE_SPLIT
	@rm -rf $(KNN_DTW_UNTAR)
	@mkdir -p $(KNN_DTW_UNTAR)
	tar -Oxzf $(shell realpath $<) | tr --delete '\n' | tr ',' '\n' | sed 's/\]\[/,/g' | tr '\n' ',' > $(KNN_DTW_UNTAR)/COMBINED
	touch $@
endif

ifeq ($(USE_MODEL),true)
# Use sub-makefile to parallel process each file
$(KNN_CONFUSION_JSONS_LOCK): $(KNN_DTW_UNTAR_LOCK) $(KNN_CONFUSION_MODEL_JSON) .flags/KNN_CONFUSION_ARGS .flags/USE_MODEL
	make -f tools/confusion_helper.mk -j8
	touch $@
else
# Use sub-makefile to parallel process each file
$(KNN_CONFUSION_JSONS_LOCK): $(KNN_DTW_UNTAR_LOCK) .flags/KNN_CONFUSION_ARGS .flags/USE_MODEL
	make -f tools/confusion_helper.mk -j8
	touch $@
endif

# Combine confusion files
$(KNN_CONFUSION_JSON): $(KNN_CONFUSION_JSONS_LOCK)
	@mkdir -p $(dir $@)
	$(KNN_COMBINER) $(shell realpath $(KNN_CONFUSION_JSONS))/ > $@
