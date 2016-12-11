# Programs
#---------
PROJECT_FOLDER=..

RAW_TO_CSV_FOLDER=$(PROJECT_FOLDER)/cpu_post_processing
RAW_TO_CSV=$(RAW_TO_CSV_FOLDER)/dist/index.js 

JOBFILE_SPLITTER_FOLDER=$(PROJECT_FOLDER)/jobfile-splitter
JOBFILE_SPLITTER=$(JOBFILE_SPLITTER_FOLDER)/index.js

JOBFILE_VALIDATOR_FOLDER=$(PROJECT_FOLDER)/jobfile-validator
JOBFILE_VALIDATOR=$(JOBFILE_VALIDATOR_FOLDER)/index.js

LOCAL_KNN_DTW_FOLDER=$(PROJECT_FOLDER)/knn_dtw
LOCAL_KNN_DTW=$(LOCAL_KNN_DTW_FOLDER)/clf.run

REMOTE_KNN_DTW_FOLDER=$(PROJECT_FOLDER)/knn_distrib
REMOTE_KNN_DTW_REQUEST=$(REMOTE_KNN_DTW_FOLDER)/request.sh
REMOTE_KNN_DTW_RESPONSE=$(REMOTE_KNN_DTW_FOLDER)/response.sh

KNN_CONFUSION_FOLDER=$(PROJECT_FOLDER)/knn_confusion
KNN_CONFUSION=$(KNN_CONFUSION_FOLDER)/index.js

KNN_RENDER_FOLDER=$(PROJECT_FOLDER)/knn_render
KNN_RENDER=$(KNN_RENDER_FOLDER)/index.js

# Files
#------
INPUT_REGEX := $(shell cat input/REGEX)
INPUT_FILES := $(shell cat input/FILES)
# Download files and MD5 files, store in download/
DOWNLOAD_FILES := $(addprefix download/,$(addsuffix .download, $(INPUT_FILES)))
MD5_FILES := $(addprefix download/,$(addsuffix .md5, $(INPUT_FILES)))
# Data files are validated .raw and .csv files stored in data/
DATA_FILES := $(addprefix data/,$(notdir $(filter %.raw %.csv,$(basename $(DOWNLOAD_FILES)))))
# CSV files are processed .raw files and .csv files stored in csv/
CSV_FILES := $(addprefix csv/,$(notdir $(addsuffix .csv, $(basename $(DATA_FILES)))))
# Job files are processed .csv files and are stored in jobs/
JOB_FILES := $(addprefix jobs/,$(notdir $(CSV_FILES:.csv=.jobfile)))

JOBFILE_COMBINED=jobfiles/combined.jobfile
JOBFILE_SPLIT=jobfiles/lock
JOBFILE_QRY=jobfiles/qry.jobfile
JOBFILE_REF=jobfiles/ref.jobfile

KNN_DTW_NAME=output/dtw.output.name
KNN_DTW_JSON=output/dtw.output.json
KNN_CONFUSION_JSON=output/confusion.output.json

KNN_DTW_MODEL_NAME=output/dtw.model.name
KNN_DTW_MODEL_JSON=output/dtw.model.json
KNN_CONFUSION_MODEL_JSON=output/confusion.model.json

KNN_RENDER_GROUND=output/render.ground.json
KNN_RENDER_RESUME=output/render.resume.json
KNN_RENDER_LATEX=output/render.latex.pdf

# Configuration stuff
#--------------------
PERCENTAGE=0.5
REMOTE_KNN=true
REMOTE_KNN_SPLIT=5
REMOTE_KNN_TIMEOUT=100000000
KNN_CONFUSION_ARGS=-f -k 3
KNN_RENDER_LATEX_ARGS=-lscx
USE_MODEL=true

# Build target
#-------------
all: prepare run

run: $(KNN_RENDER_RESUME) $(KNN_RENDER_LATEX)

jobfiles: $(JOB_FILES)

csvfiles: $(CSV_FILES)

datafiles: $(DATA_FILES)

md5files: $(MD5_FILES)

downloadfiles: $(DOWNLOAD_FILES)

clean:
	rm -rf data
	rm -rf jobs
	rm -rf jobfiles
	rm -rf output
	rm -rf csv

# Rebuild on changed compiler flags
#----------------------------------
.flags/%: force
	@mkdir -p .flags
	@echo '$($(@F))' | cmp -s - $@ || echo '$($(@F))' > $@

# Install software
#-----------------
prepare: $(RAW_TO_CSV) $(LOCAL_KNN_DTW)
	@if [ ! -d $(JOBFILE_SPLITTER_FOLDER)/node_modules/ ]; then make build_JOBFILE_SPLITTER; fi
	@if [ ! -d $(KNN_CONFUSION_FOLDER)/node_modules/ ]; then make build_KNN_CONFUSION; fi
	@if [ ! -d $(KNN_RENDER_FOLDER)/node_modules/ ]; then make build_KNN_RENDER; fi

build_JOBFILE_SPLITTER:
	@echo ""
	@echo "Installing jobfile-splitter"
	cd $(JOBFILE_SPLITTER_FOLDER) && npm i 1>/dev/null

build_KNN_CONFUSION:
	@echo ""
	@echo "Installing knn_confusion"
	cd $(KNN_CONFUSION_FOLDER) && npm i 1>/dev/null

build_KNN_RENDER:
	@echo ""
	@echo "Installing knn_render"
	cd $(KNN_RENDER_FOLDER) && npm i 1>/dev/null

$(RAW_TO_CSV): 
	@echo ""
	@echo "Installing cpu processing"
	cd $(RAW_TO_CSV_FOLDER) && npm run compile 1>/dev/null

ifeq ($(REMOTE_KNN),true)
$(LOCAL_KNN_DTW):
else
$(LOCAL_KNN_DTW):
	@echo ""
	@echo "Installing knn-dtw (local)"
	cd $(LOCAL_KNN_DTW_FOLDER) && make -j8 1>/dev/null
endif

# Downloading
#------------
download/%.download:
	@mkdir -p download
	curl --fail --silent -o $@ http://skeen.website:3001/symlinks/$(INPUT_REGEX)/$(@F:.download= )

download/%.md5: download/%.download
	@mkdir -p download
	md5sum $< | cut -f1 -d' ' | tr --delete '\n' > $@

data/%: download/%.download download/%.md5
	@mkdir -p data
	@if [ "$(shell curl --fail --silent http://skeen.website:3001/md5/$(INPUT_REGEX)/$(@F))" = "$(shell cat download/$(@F).md5)" ]; then \
		echo "MD5 check passed: '$@'"; \
		cp $< $@; \
	else \
		echo "MD5 check failed: '$@', removing $<"; \
		rm download/$(@F).download download/$(@F).md5; \
		false; \
	fi

# Processing
#-----------
# .raw to csv
csv/%.csv: data/%.raw
	@mkdir -p csv/
	cat $< | $(RAW_TO_CSV) > $@
	
# .csv to .csv (copy)
csv/%.csv: data/%.csv
	@mkdir -p csv/
	cp $< $@

# .csv to .jobfiles
jobs/%.jobfile: csv/%.csv
	@mkdir -p jobs
	@# This replaces $(CSV_TO_JOBFILE)
	basename $< | cut -f1 -d'_' | tr --delete '\n' > $@
	echo " $<" >> $@
	cat $< | tail -n +2 | cut -f2 -d',' | tr --delete ' ' | tr '\n' ' ' >> $@
	echo "" >> $@
	cat $< | tail -n +2 | cut -f1 -d',' | tr --delete ' ' | tr '\n' ' ' >> $@
	echo "" >> $@
	@# Validate that the jobfile was created correctly (very no data is dropped too)
	cat $@ | $(JOBFILE_VALIDATOR) $(shell cat $< | wc -l | xargs expr -1 + ) || rm $@

# .jobfiles to .jobfile (combine)
$(JOBFILE_COMBINED): $(JOB_FILES)
	@mkdir -p jobfiles
	cat $^ > $@
	@# We trust cat to work
	@#cat $@ | ../jobfile-validator/index.js

# .jobfile to .jobfiles (split)
$(JOBFILE_SPLIT): $(JOBFILE_COMBINED) .flags/PERCENTAGE
	@mkdir -p jobfiles
	cat $< | $(JOBFILE_SPLITTER) -O jobfiles -rbp $(PERCENTAGE)
	touch $@
	@# Validate output jobfiles was created correctly
	cat $(JOBFILE_QRY) | ../jobfile-validator/index.js || rm $(JOBFILE_QRY) $@
	cat $(JOBFILE_REF) | ../jobfile-validator/index.js || rm $(JOBFILE_REF) $@

$(JOBFILE_QRY): $(JOBFILE_SPLIT)
$(JOBFILE_REF): $(JOBFILE_SPLIT)

ifeq ($(REMOTE_KNN),true)
$(KNN_DTW_NAME): $(JOBFILE_QRY) $(JOBFILE_REF)
	@mkdir -p output
	$(REMOTE_KNN_DTW_REQUEST) $(JOBFILE_REF) $(JOBFILE_QRY) "" $(REMOTE_KNN_SPLIT) $(REMOTE_KNN_TIMEOUT) > $@

$(KNN_DTW_JSON): $(KNN_DTW_NAME)
	@mkdir -p output
	cat $< | xargs $(REMOTE_KNN_DTW_RESPONSE) > $@
else
# .jobfiles to .json
$(KNN_DTW_JSON): $(JOBFILE_QRY) $(JOBFILE_REF)
	@mkdir -p output
	$(LOCAL_KNN_DTW) --query_filename=$(JOBFILE_QRY) --reference_filename=$(JOBFILE_REF) > $@
endif

ifeq ($(USE_MODEL),true)
ifeq ($(REMOTE_KNN),true)
$(KNN_DTW_MODEL_NAME): $(JOBFILE_COMBINED) .flags/USE_MODEL
	@mkdir -p output
	$(REMOTE_KNN_DTW_REQUEST) $(JOBFILE_COMBINED) $(JOBFILE_COMBINED) "-m" $(REMOTE_KNN_SPLIT) $(REMOTE_KNN_TIMEOUT) > $@

$(KNN_DTW_MODEL_JSON): $(KNN_DTW_MODEL_NAME)
	@mkdir -p output
	cat $< | xargs $(REMOTE_KNN_DTW_RESPONSE) > $@
else
# .jobfiles to .json
$(KNN_DTW_MODEL_JSON): $(JOBFILE_COMBINED)
	@mkdir -p output
	$(LOCAL_KNN_DTW) --query_filename=$(JOBFILE_COMBINED) --reference_filename=$(JOBFILE_COMBINED) -m > $@
endif

# Generate model
$(KNN_CONFUSION_MODEL_JSON): $(KNN_DTW_MODEL_JSON)
	@mkdir -p output
	cat $< | $(KNN_CONFUSION) --modelling > $@

# .json to .json (processing) - using model
$(KNN_CONFUSION_JSON): $(KNN_DTW_JSON) $(KNN_CONFUSION_MODEL_JSON) .flags/KNN_CONFUSION_ARGS
	@mkdir -p output
	cat $(KNN_DTW_JSON) | $(KNN_CONFUSION) --statistics=$(KNN_CONFUSION_MODEL_JSON) $(KNN_CONFUSION_ARGS) | python -m json.tool > $@
else
# .json to .json (processing)
$(KNN_CONFUSION_JSON): $(KNN_DTW_JSON) .flags/KNN_CONFUSION_ARGS .flags/USE_MODEL
	@mkdir -p output
	cat $< | $(KNN_CONFUSION) $(KNN_CONFUSION_ARGS) | python -m json.tool > $@
endif

# .json to .json (processing)
$(KNN_RENDER_GROUND): $(KNN_CONFUSION_JSON)
	@mkdir -p output
	cat $< | $(KNN_RENDER) -g >$@

# .json to .json (processing)
$(KNN_RENDER_RESUME): $(KNN_CONFUSION_JSON)
	@mkdir -p output
	cat $< | $(KNN_RENDER) -r >$@

# .json to .pdf
$(KNN_RENDER_LATEX): $(KNN_CONFUSION_JSON) .flags/KNN_RENDER_LATEX_ARGS
	@mkdir -p output
	cat $< | $(KNN_RENDER) $(KNN_RENDER_LATEX_ARGS) | lualatex -jobname $(@D)/$(basename $(@F))
	@rm $(@D)/$(basename $(@F)).log
	@rm $(@D)/$(basename $(@F)).aux

print: $(KNN_RENDER_LATEX) $(KNN_RENDER_RESUME)
	lpr -P Ada-222-b -o fit-to-page $(KNN_RENDER_LATEX)
	lpr -P Ada-222-b $(KNN_RENDER_RESUME)

# These don't really output files
.PHONY: all prepare run clean force print build_JOBFILE_SPLITTER build_KNN_CONFUSION build_KNN_RENDER
.SECONDARY: $(INPUT_FILES) $(DOWNLOAD_FILES) $(MD5_FILES) $(DATA_FILES) $(CSV_FILES) $(JOB_FILES)
