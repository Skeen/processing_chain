# Programs
#---------
PROJECT_FOLDER=..

RAW_TO_CSV_FOLDER=$(PROJECT_FOLDER)/cpu_post_processing
RAW_TO_CSV=$(RAW_TO_CSV_FOLDER)/dist/index.js 

JOBFILE_SPLITTER_FOLDER=$(PROJECT_FOLDER)/jobfile-splitter
JOBFILE_SPLITTER=$(JOBFILE_SPLITTER_FOLDER)/index.js

LOCAL_KNN_DTW_FOLDER=$(PROJECT_FOLDER)/knn_dtw
LOCAL_KNN_DTW=$(LOCAL_KNN_DTW_FOLDER)/clf.run

REMOTE_KNN_DTW_FOLDER=$(PROJECT_FOLDER)/knn_distrib
REMOTE_KNN_DTW=$(REMOTE_KNN_DTW_FOLDER)/request.sh

KNN_CONFUSION_FOLDER=$(PROJECT_FOLDER)/knn_confusion
KNN_CONFUSION=$(KNN_CONFUSION_FOLDER)/index.js

KNN_RENDER_FOLDER=$(PROJECT_FOLDER)/knn_render
KNN_RENDER=$(KNN_RENDER_FOLDER)/index.js

# Files
#------
RAW_INPUT_FILES := $(wildcard data/*.raw)
CSV_INPUT_FILES := $(wildcard data/*.csv)
CSV_FILES := $(addprefix csv/,$(notdir $(RAW_INPUT_FILES:.raw=.csv) $(CSV_INPUT_FILES:.csv=.csv)))
JOB_FILES := $(addprefix jobs/,$(notdir $(CSV_FILES:.csv=.jobfile)))

JOBFILE_COMBINED=jobfiles/combined.jobfile
JOBFILE_SPLIT=jobfiles/lock
JOBFILE_QRY=jobfiles/qry.jobfile
JOBFILE_REF=jobfiles/ref.jobfile

KNN_DTW_JSON=output/dtw.output.json
KNN_CONFUSION_JSON=output/confusion.output.json

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
REMOTE_KNN_TIMEOUT=1000000
KNN_CONFUSION_ARGS=-f -k 3
KNN_RENDER_LATEX_ARGS=-lscx
USE_MODEL=true

# Build target
#-------------
all: prepare run

run: $(KNN_RENDER_RESUME) $(KNN_RENDER_LATEX)

#output_file.csv: .flags/PERCENTAGE
#	@echo "$(PERCENTAGE)" > output_file.csv
#	@echo "BUILD"

clean:
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

$(LOCAL_KNN_DTW):
	@echo ""
	@echo "Installing knn-dtw (local)"
	cd $(LOCAL_KNN_DTW_FOLDER) && make -j8 1>/dev/null

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
	# This replaces $(CSV_TO_JOBFILE)
	basename $< | cut -f1 -d'_' | tr --delete '\n' > $@
	echo " $<" >> $@
	cat $< | tail -n +2 | cut -f2 -d',' | tr --delete ' ' | tr '\n' ' ' >> $@
	echo "" >> $@
	cat $< | tail -n +2 | cut -f1 -d',' | tr --delete ' ' | tr '\n' ' ' >> $@
	echo "" >> $@

# .jobfiles to .jobfile (combine)
$(JOBFILE_COMBINED): $(JOB_FILES)
	@mkdir -p jobfiles
	cat $^ > $@

# .jobfile to .jobfiles (split)
$(JOBFILE_SPLIT): $(JOBFILE_COMBINED) .flags/PERCENTAGE
	@mkdir -p jobfiles
	cat $< | $(JOBFILE_SPLITTER) -O jobfiles -rbp $(PERCENTAGE)
	touch $@

$(JOBFILE_QRY): $(JOBFILE_SPLIT)
$(JOBFILE_REF): $(JOBFILE_SPLIT)

# .jobfiles to .json
$(KNN_DTW_JSON): $(JOBFILE_QRY) $(JOBFILE_REF)
	@mkdir -p output
ifeq ($(REMOTE_KNN),true)
	$(REMOTE_KNN_DTW) $(JOBFILE_REF) $(JOBFILE_QRY) "" $(REMOTE_KNN_SPLIT) $(REMOTE_KNN_TIMEOUT) > $@
else
	$(LOCAL_KNN_DTW) --query_filename=$(JOBFILE_QRY) --reference_filename=$(JOBFILE_REF) > $@
endif

ifeq ($(USE_MODEL),true)
# Generate model using dtw
$(KNN_DTW_MODEL_JSON): $(JOBFILE_COMBINED) .flags/USE_MODEL
	@mkdir -p output
ifeq ($(REMOTE_KNN),true)
	$(REMOTE_KNN_DTW) $(JOBFILE_COMBINED) $(JOBFILE_COMBINED) "-m" $(REMOTE_KNN_SPLIT) $(REMOTE_KNN_TIMEOUT) > $@
else
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

# These don't really output files
.PHONY: all prepare run clean force build_JOBFILE_SPLITTER build_KNN_CONFUSION build_KNN_RENDER
.SECONDARY: $(JOB_FILES) $(CSV_FILES)
