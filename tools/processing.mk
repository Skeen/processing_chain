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

# We need these for make to build the dependency graph correctly
$(JOBFILE_QRY): $(JOBFILE_SPLIT)
$(JOBFILE_REF): $(JOBFILE_SPLIT)
