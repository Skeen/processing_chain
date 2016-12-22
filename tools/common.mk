include tools/config.mk

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

KNN_COMBINER_FOLDER=$(PROJECT_FOLDER)/knn_combiner
KNN_COMBINER=$(KNN_COMBINER_FOLDER)/index.js

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
KNN_DTW_TAR=output/dtw.output.tar.gz
KNN_DTW_JSONS=output/dtw.output/PROCESSED
KNN_CONFUSION_JSONS=output/confusion.output/DONE
KNN_CONFUSION_JSON=output/confusion.output.json

KNN_DTW_MODEL_NAME=output/dtw.model.name
KNN_DTW_MODEL_TAR=output/dtw.model.tar.gz
KNN_DTW_MODEL_JSON=output/dtw.model.json
KNN_CONFUSION_MODEL_JSON=output/confusion.model.json

KNN_RENDER_GROUND=output/render.ground.json
KNN_RENDER_RESUME=output/render.resume.json
KNN_RENDER_LATEX=output/render.latex.pdf

# Helper targets
#---------------
.flags/%: force
	@mkdir -p $(dir $@)
	@echo '$($(@F))' | cmp -s - $@ || echo '$($(@F))' > $@

