# Arguments
#----------
INPUT_FOLDER?=
OUTPUT_FOLDER?=
KNN_CONFUSION_ARGS?=
MODEL?=

# Programs
#---------
PROJECT_FOLDER=..

KNN_CONFUSION_FOLDER=$(PROJECT_FOLDER)/knn_confusion
KNN_CONFUSION=$(KNN_CONFUSION_FOLDER)/index.js

INPUT := $(wildcard $(INPUT_FOLDER)/*)
OUTPUT := $(addprefix $(OUTPUT_FOLDER)/,$(notdir $(addsuffix .json, $(INPUT))))

ifeq ($(MODEL),)
$(OUTPUT_FOLDER)/%.json: $(INPUT_FOLDER)/% .flags/KNN_CONFUSION_ARGS .flags/USE_MODEL
	@mkdir -p $(OUTPUT_FOLDER)
	cat $< | $(KNN_CONFUSION) $(KNN_CONFUSION_ARGS) | python -m json.tool > $@

else
$(OUTPUT_FOLDER)/%.json: $(INPUT_FOLDER)/% .flags/KNN_CONFUSION_ARGS .flags/USE_MODEL
	@mkdir -p $(OUTPUT_FOLDER)
	cat $< | $(KNN_CONFUSION) $(KNN_CONFUSION_ARGS) --statistics=$(KNN_CONFUSION_MODEL_JSON) | python -m json.tool > $@
endif

all: $(OUTPUT)
