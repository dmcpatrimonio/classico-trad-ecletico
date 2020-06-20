# Global variables {{{1
# ================
# Where make should look for things
VPATH = lib
vpath %.bib .:bibliography
vpath %.csl styles
vpath %.yaml .:spec:_data
vpath default.% lib:lib/templates:lib/pandoc-templates
vpath reference.% lib:lib/templates:lib/pandoc-templates

# Branch-specific targets and recipes {{{1
# ===================================

# Jekyll {{{2
# ------
PAGES_SRC  = $(filter-out README.md,$(wildcard *.md))
PAGES_OUT := $(patsubst %.md,tmp/%.md, $(PAGES_SRC))

build :
	docker run --rm -v "`pwd`:/srv/jekyll" jekyll/jekyll:3.8.5 \
		/bin/bash -c "chmod 777 /srv/jekyll && jekyll build --future"

pandoc : $(PAGES_OUT)
	@-rm -rf styles

tmp/%.md : %.md jekyll.yaml default.jekyll
	@test -e tmp || mkdir tmp
	@test -e styles || git clone https://github.com/citation-style-language/styles.git
	docker run --rm -v "`pwd`:/data" --user `id -u`:`id -g` \
		palazzo/pandoc-crossref:2.9.2.1 $< -o $@ -d spec/jekyll.yaml

# VI Enanparq {{{2
# -----------
ENANPARQ_SRC  = $(wildcard 6enanparq-*.md)
ENANPARQ_TMP := $(patsubst %.md,%.tmp, $(ENANPARQ_SRC))

6enanparq.docx : $(ENANPARQ_TMP) 6enanparq-sl.yaml \
	6enanparq-metadata.yaml default.opendocument reference.odt
	docker run --rm -v "`pwd`:/data" --user `id -u`:`id -g` \
		palazzo/pandoc-crossref:2.9.2.1 \
		-o 6enanparq.odt -d spec/6enanparq-sl.yaml \
		6enanparq-intro.md 6enanparq-palazzo.tmp \
		6enanparq-florentino.tmp 6enanparq-gil_cornet.tmp \
		6enanparq-tinoco.tmp 6enanparq-metadata.yaml
	docker run --rm -v "`pwd`:/home/alpine" -v assets/fonts:/usr/share/fonts:ro \
		woahbase/alpine-libreoffice:x86_64 --convert-to docx 6enanparq.odt

%.tmp : %.md concat.yaml biblio.bib
	docker run --rm -v "`pwd`:/data" --user `id -u`:`id -g` \
		palazzo/pandoc-crossref:2.9.2.1 -o $@ -d spec/concat.yaml $<

# Figuras a partir de vetores {{{2
# ---------------------------

figures/%.png : %.svg
	inkscape -f $< -e $@ -d 96

# vim: set foldmethod=marker tw=72 :
