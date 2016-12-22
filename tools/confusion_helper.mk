include tools/common.mk

INPUT_FOLDER := $(KNN_DTW_UNTAR)
OUTPUT_FOLDER := $(KNN_CONFUSION_JSONS)
INPUT := $(wildcard $(INPUT_FOLDER)/*)
OUTPUT := $(addprefix $(OUTPUT_FOLDER)/,$(notdir $(addsuffix .json, $(INPUT))))

ifeq ($(USE_MODEL),false)
$(OUTPUT_FOLDER)/%.json: $(INPUT_FOLDER)/% .flags/KNN_CONFUSION_ARGS .flags/USE_MODEL
	@mkdir -p $(dir $@)
	cat $< | $(KNN_CONFUSION) $(KNN_CONFUSION_ARGS) | python -m json.tool > $@

else
$(OUTPUT_FOLDER)/%.json: $(INPUT_FOLDER)/% .flags/KNN_CONFUSION_ARGS .flags/USE_MODEL
	@mkdir -p $(dir $@)
	cat $< | $(KNN_CONFUSION) $(KNN_CONFUSION_ARGS) --statistics=$(KNN_CONFUSION_MODEL_JSON) | python -m json.tool > $@
endif

all: $(OUTPUT)
