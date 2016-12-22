# Process our confusion matrix into output
#-----------------------------------------

# .json to .json (processing)
$(KNN_RENDER_GROUND): $(KNN_CONFUSION_JSON)
	@mkdir -p $(dir $@)
	cat $< | $(KNN_RENDER) -g >$@

# .json to .json (processing)
$(KNN_RENDER_RESUME): $(KNN_CONFUSION_JSON)
	@mkdir -p $(dir $@)
	cat $< | $(KNN_RENDER) -r >$@

# .json to .pdf
$(KNN_RENDER_LATEX): $(KNN_CONFUSION_JSON) .flags/KNN_RENDER_LATEX_ARGS
	@mkdir -p $(dir $@)
	cat $< | $(KNN_RENDER) $(KNN_RENDER_LATEX_ARGS) | lualatex -jobname $(@D)/$(basename $(@F))
	@rm $(@D)/$(basename $(@F)).log
	@rm $(@D)/$(basename $(@F)).aux

