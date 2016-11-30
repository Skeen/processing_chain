# Programs
#---------
RAW_TO_CSV_FOLDER=../cpu_post_processing
RAW_TO_CSV=$(RAW_TO_CSV_FOLDER)/dist/index.js 

CSV_TO_JOBFILE_FOLDER=../csv-to-jobfile
CSV_TO_JOBFILE=$(CSV_TO_JOBFILE_FOLDER)/index.js

JOBFILE_SPLITTER_FOLDER=../jobfile-splitter
JOBFILE_SPLITTER=$(JOBFILE_SPLITTER_FOLDER)/index.js

LOCAL_KNN_DTW_FOLDER=../knn_dtw
LOCAL_KNN_DTW=$(LOCAL_KNN_DTW_FOLDER)/clf.run

REMOTE_KNN_DTW_FOLDER=../knn_distrib
REMOTE_KNN_DTW=$(REMOTE_KNN_DTW_FOLDER)/request.sh

KNN_CONFUSION_FOLDER=../knn_confusion
KNN_CONFUSION=$(KNN_CONFUSION_FOLDER)/index.js

KNN_RENDER_FOLDER=../knn_render/
KNN_RENDER=$(KNN_RENDER_FOLDER)/index.js

# Files
#------
RAW_INPUT_FILES := $(wildcard data/*.raw)
CSV_INPUT_FILES := $(wildcard data/*.csv)
CSV_FILES := $(addprefix csv/,$(notdir $(RAW_INPUT_FILES:.raw=.csv) $(CSV_INPUT_FILES:.csv=.csv)))

JOBFILE_COMBINED=jobfiles/combined.jobfile
JOBFILE_QRY=jobfiles/qry.jobfile
JOBFILE_REF=jobfiles/ref.jobfile

KNN_DTW_JSON=output/output.json
KNN_CONFUSION_JSON=output/confusion.json

KNN_RENDER_GROUND=output/render.ground.json
KNN_RENDER_RESUME=output/render.resume.json
KNN_RENDER_LATEX=output/render.latex.pdf

# Configuration stuff
#--------------------
PERCENTAGE=0.5
REMOTE_KNN=false
DTW_ARGS=
KNN_CONFUSION_ARGS=-f -k5
KNN_RENDER_LATEX_ARGS=-lscx

# Build target
#-------------
all: prepare $(KNN_RENDER_LATEX)

# Install software
#-----------------
prepare: $(RAW_TO_CSV) $(LOCAL_KNN_DTW)
	@if [ ! -d $(CSV_TO_JOBFILE_FOLDER)/node_modules/ ]; then make build_CSV_TO_JOBFILE; fi
	@if [ ! -d $(JOBFILE_SPLITTER_FOLDER)/node_modules/ ]; then make build_JOBFILE_SPLITTER; fi
	@if [ ! -d $(KNN_CONFUSION_FOLDER)/node_modules/ ]; then make build_KNN_CONFUSION; fi
	@if [ ! -d $(KNN_RENDER_FOLDER)/node_modules/ ]; then make build_KNN_RENDER; fi

build_CSV_TO_JOBFILE:
	@echo ""
	@echo "Installing csv-to-jobfile"
	cd $(RAW_TO_CSV_FOLDER) && npm i 1>/dev/null

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

# .csv to .jobfile
$(JOBFILE_COMBINED): $(CSV_FILES)
	@mkdir -p jobfiles
	$(CSV_TO_JOBFILE) csv/ > $@

# .jobfile to .jobfiles (split)
$(JOBFILE_QRY) $(JOBFILE_REF): $(JOBFILE_COMBINED)
	@mkdir -p jobfiles
	cat $< | $(JOBFILE_SPLITTER) -O jobfiles -rbp $(PERCENTAGE)

# .jobfiles to .json
$(KNN_DTW_JSON): $(JOBFILE_QRY) $(JOBFILE_REF)
	@mkdir -p output
ifeq ($(REMOTE_KNN),true)
	$(REMOTE_KNN_DTW) $(JOBFILE_REF) $(JOBFILE_QRY) "$(DTW_ARGS)" > $@
else
	$(LOCAL_KNN_DTW) --query_filename=$(JOBFILE_QRY) --reference_filename=$(JOBFILE_REF) $(DTW_ARGS) > $@
endif

# .json to .json (processing)
$(KNN_CONFUSION_JSON): $(KNN_DTW_JSON)
	@mkdir -p output
	cat $< | $(KNN_CONFUSION) $(KNN_CONFUSION_ARGS) > $@

# .json to .json (processing)
$(KNN_RENDER_GROUND): $(KNN_CONFUSION_JSON)
	@mkdir -p output
	cat $< | $(KNN_RENDER) -g >$@

# .json to .json (processing)
$(KNN_RENDER_RESUME): $(KNN_CONFUSION_JSON)
	@mkdir -p output
	cat $< | $(KNN_RENDER) -r >$@

# .json to .pdf
$(KNN_RENDER_LATEX): $(KNN_CONFUSION_JSON)
	@mkdir -p output
	cat $< | $(KNN_RENDER) $(KNN_RENDER_LATEX_ARGS) | lualatex -jobname $@

# These don't really output files
.PHONY: all prepare build_CSV_TO_JOBFILE build_JOBFILE_SPLITTER build_KNN_CONFUSION build_KNN_RENDER
# These are build by multi-target rule, so non-parallel for this one
.NOTPARALLEL: $(JOBFILE_QRY) $(JOBFILE_REF)
