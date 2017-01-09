all: prepare run

# Helpers
#--------
include tools/common.mk
include tools/install.mk

# Phases
#-------
include tools/download.mk
include tools/processing.mk
include tools/dtw.mk
include tools/confusion.mk
include tools/render.mk

# Build target
#-------------
run: resume
	cat $(KNN_RENDER_RESUME) | python -m json.tool

resume: $(KNN_RENDER_RESUME)
pdf: $(KNN_RENDER_LATEX)

download: $(DATA_FILES)

jobs: $(JOB_FILES)

clean:
	rm -rf data
	rm -rf jobs
	rm -rf jobfiles
	rm -rf output
	rm -rf csv

clean_output:
	rm -rf output/confusion
	rm -rf output/json
	rm -rf output/render
	rm -rf output/tmp

# These don't really output files
.PHONY: all prepare run resume pdf download jobs clean clean_output force print build_JOBFILE_SPLITTER build_KNN_CONFUSION build_KNN_COMBINER build_KNN_RENDER
.SECONDARY: $(INPUT_FILES) $(DOWNLOAD_FILES) $(MD5_FILES) $(DATA_FILES) $(CSV_FILES) $(JOB_FILES)
