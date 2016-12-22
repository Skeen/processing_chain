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
run: $(KNN_RENDER_RESUME) $(KNN_RENDER_LATEX) $(KNN_RENDER_GROUND)

clean:
	rm -rf data
	rm -rf jobs
	rm -rf jobfiles
	rm -rf output
	rm -rf csv

# These don't really output files
.PHONY: all prepare run clean force print build_JOBFILE_SPLITTER build_KNN_CONFUSION build_KNN_COMBINER build_KNN_RENDER
.SECONDARY: $(INPUT_FILES) $(DOWNLOAD_FILES) $(MD5_FILES) $(DATA_FILES) $(CSV_FILES) $(JOB_FILES)
