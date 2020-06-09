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
PAGES_SRC  = $(wildcard *.md)
PAGES_OUT := $(patsubst %,tmp/%, $(PAGES_SRC))

build: $(PAGES_OUT)
	bundle exec jekyll build 2>&1 | egrep -v 'deprecated|obsoleta'

tmp/%.md : %.md jekyll.yaml lib/templates/default.jekyll
	docker run --rm -v "`pwd`:/data" --user `id -u`:`id -g` \
		palazzo/pandoc-xnos:2.9.2.1 $< -o $@ -d spec/jekyll.yaml

# VI Enanparq {{{2
# -----------
ENANPARQ_SRC  = $(wildcard 6enanparq-*.md)
ENANPARQ_TMP := $(patsubst %.md,%.tmp, $(ENANPARQ_SRC))
.INTERMEDIATE : $(ENANPARQ_TMP) _book/6enanparq.odt

6enanparq.docx : 6enanparq.odt
	docker run --rm -v "`pwd`:/home/alpine" \
		woahbase/alpine-libreoffice:x86_64 --convert-to docx $<

6enanparq.odt : $(ENANPARQ_TMP) 6enanparq-sl.yaml \
	6enanparq-metadata.yaml default.opendocument reference.odt
	docker run --rm -v "`pwd`:/data" --user `id -u`:`id -g` \
		palazzo/pandoc-xnos:2.9.2.1 \
		-o $@ -d spec/6enanparq-sl.yaml \
		6enanparq-intro.md 6enanparq-palazzo.tmp \
		6enanparq-florentino.tmp 6enanparq-gil_cornet.tmp \
		6enanparq-tinoco.tmp 6enanparq-metadata.yaml

%.tmp : %.md concat.yaml biblio.bib
	docker run --rm -v "`pwd`:/data" --user `id -u`:`id -g` \
		palazzo/pandoc-xnos:2.9.2.1 -o $@ -d spec/concat.yaml $<

# Figuras a partir de vetores {{{2
# ---------------------------

figures/%.png : %.svg
	inkscape -f $< -e $@ -d 96

# Install and cleanup {{{1
# ===================
.PHONY : serve link-template license clean

serve : 
	bundle exec jekyll serve 2>&1 | egrep -v 'deprecated|obsoleta'

link-template :
	# Generating a repo from a GitHub template breaks the
	# submodules. As a workaround, we create a branch that clones
	# directly from the template repo, activate the submodules
	# there, then merge it into whatever branch was previously
	# active (the master branch if your repo has just been
	# initialized).
	-git remote add template git@github.com:p3palazzo/research_template.git
	git fetch template
	git checkout -B template --track template/master
	git checkout -

license :
	source .venv/bin/activate && \
		lice --header cc_by >> README.md && \
		lice cc_by -f LICENSE

# `make clean` will clear out a few standard folders where only compiled
# files should be. Anything you might have placed manually in them will
# also be deleted!
clean :
	-rm -rf _site tmp

# vim: set foldmethod=marker tw=72 :
