# Process our .tar file into .json (confusion)
#---------------------------------------------
include tools/confusion_helper.mk

#-------#
# Model #
#-------#
# Unpack tar file, and combine pieces into a single json
$(KNN_DTW_MODEL_JSON): $(KNN_DTW_MODEL_TAR)
	$(eval TMP_FOLDER=$(shell echo $@ | sed 's#\(.*\)\..*#\1#'))
	mkdir -p $(TMP_FOLDER)
	cd $(TMP_FOLDER) && tar -xzf $(shell realpath $<) --strip-components 1 
	cat $(TMP_FOLDER)/* | tr --delete '\n' | tr ',' '\n' | sed 's/\]\[/,/g' | tr '\n' ',' > $@

# Generate model
$(KNN_CONFUSION_MODEL_JSON): $(KNN_DTW_MODEL_JSON)
	@mkdir -p output
	cat $< | $(KNN_CONFUSION) --modelling > $@

#---------#
# Reading #
#---------#
# Unpack our tar file, and create dummy file
$(KNN_DTW_JSONS): $(KNN_DTW_TAR)
	$(eval DTW_JSONS_DIR=$(shell dirname $@))
	@mkdir -p $(DTW_JSONS_DIR)
	cd $(DTW_JSONS_DIR) && tar -xzf $(shell realpath $<) --strip-components 1 
	echo "{}" > $@

ifeq ($(USE_MODEL),true)
# Use sub-makefile to parallel process each file
$(KNN_CONFUSION_JSONS): $(KNN_DTW_JSONS) $(KNN_CONFUSION_MODEL_JSON) .flags/KNN_CONFUSION_ARGS .flags/USE_MODEL
	INPUT_FOLDER=$(shell dirname $<) \
	OUTPUT_FOLDER=$(shell dirname $@) \
	KNN_CONFUSION_ARGS="$(KNN_CONFUSION_ARGS)" \
	MODEL=$(MODEL) \
		make -f Makefile_helper -j8
	echo "{}" > $@
else
# Use sub-makefile to parallel process each file
$(KNN_CONFUSION_JSONS): $(KNN_DTW_JSONS) .flags/KNN_CONFUSION_ARGS .flags/USE_MODEL
	INPUT_FOLDER=$(shell dirname $<) \
	OUTPUT_FOLDER=$(shell dirname $@) \
	KNN_CONFUSION_ARGS="$(KNN_CONFUSION_ARGS)" \
	MODEL= \
		make -f Makefile_helper -j8
	echo "{}" > $@
endif

# Combine confusion files
$(KNN_CONFUSION_JSON): $(KNN_CONFUSION_JSONS)
	$(KNN_COMBINER) $(shell realpath $(shell dirname $<)) > $@


