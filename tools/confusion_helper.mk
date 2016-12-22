include tools/common.mk

INPUT_FOLDER := $(dir $(KNN_DTW_JSONS))
OUTPUT_FOLDER := $(dir $(KNN_CONFUSION_JSONS))
INPUT := $(wildcard $(INPUT_FOLDER)/*)
OUTPUT := $(addprefix $(OUTPUT_FOLDER)/,$(notdir $(addsuffix .json, $(INPUT))))

ifeq ($(MODEL),)
$(OUTPUT_FOLDER)/%.json: $(INPUT_FOLDER)/% .flags/KNN_CONFUSION_ARGS .flags/USE_MODEL
	@rm -rf $(dir $@)
	@mkdir -p $(dir $@)
	cat $< | $(KNN_CONFUSION) $(KNN_CONFUSION_ARGS) | python -m json.tool > $@

else
$(OUTPUT_FOLDER)/%.json: $(INPUT_FOLDER)/% .flags/KNN_CONFUSION_ARGS .flags/USE_MODEL
	@rm -rf $(dir $@)
	@mkdir -p $(dir $@)
	cat $< | $(KNN_CONFUSION) $(KNN_CONFUSION_ARGS) --statistics=$(KNN_CONFUSION_MODEL_JSON) | python -m json.tool > $@
endif

all: $(OUTPUT)
