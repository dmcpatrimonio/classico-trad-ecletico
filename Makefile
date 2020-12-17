# Global variables {{{1
# ================
# Where make should look for things
VPATH = lib
vpath %.csl styles
vpath %.yaml .:spec:_data
vpath default.% lib:lib/templates:lib/pandoc-templates
vpath reference.% lib:lib/templates:lib/pandoc-templates

PANDOC/CROSSREF := pandoc/crossref:2.11.2
PANDOC/LATEX    := pandoc/latex:2.11.2

PAGES_SRC  = $(filter-out README.md,$(wildcard *.md))
PAGES_OUT := $(patsubst %.md,tmp/%.md, $(PAGES_SRC))

build :
	docker run -v "`pwd`:/srv/jekyll" jekyll/jekyll:3.8.5 \
		/bin/bash -c "chmod 777 /srv/jekyll && jekyll build --future"

pandoc : $(PAGES_OUT)
	@-rm -rf styles

tmp/%.md : %.md biblio.bib jekyll.yaml | styles
	@mkdir -p tmp
	docker run -v "`pwd`:/data" --user `id -u`:`id -g` \
		$(PANDOC/CROSSREF) $< -o $@ -d jekyll.yaml

# Figuras a partir de vetores {{{2
# ---------------------------

figures/%.png : %.svg
	@test -e figures || mkdir figures
	inkscape -f $< -e $@ -d 96

styles:
	git clone --depth 1 https://github.com/citation-style-language/styles.git
# vim: set foldmethod=marker tw=72 :
