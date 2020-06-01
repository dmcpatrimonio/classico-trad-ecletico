# Global variables {{{1
# ================
# Where make should look for things
VPATH = lib
vpath %.csl lib/styles
vpath %.yaml .:spec:docs/_data
vpath default.% lib/templates:lib/pandoc-templates
vpath reference.% lib/templates:lib/pandoc-templates
# Edit the path below to point to the location of your binary files.
SHARE = ~/integra/arqtrad

# Branch-specific targets and recipes {{{1
# ===================================

# This is the first recipe in the Makefile. As such, it is the one that
# runs when calling 'make' with no arguments. List as its requirements
# anything you want to build (deploy) for release.
publish : setup _site/index.html  _book/6enanparq.docx

# Jekyll {{{2
# ------
PAGES_SRC  = $(wildcard *.md)
PAGES_OUT := $(patsubst %,tmp/%, $(PAGES_SRC))

serve : _site/.nojekyll
	bundle exec jekyll serve 2>&1 | egrep -v 'deprecated|obsoleta'

build: $(PAGES_OUT)
	bundle exec jekyll build 2>&1 | egrep -v 'deprecated|obsoleta'

tmp/%.md : %.md jekyll.yaml lib/templates/default.jekyll
	docker run --rm -v "`pwd`:/data" --user `id -u`:`id -g` \
		pandoc/core:2.9.2.1 $< -o $@ -d spec/jekyll.yaml

# VI Enanparq {{{2
# -----------
ENANPARQ_SRC  = $(wildcard 6enanparq-*.md)
ENANPARQ_TMP := $(patsubst %.md,%.tmp, $(ENANPARQ_SRC))
.INTERMEDIATE : $(ENANPARQ_TMP) _book/6enanparq.odt

_book/6enanparq.docx : _book/6enanparq.odt
	libreoffice --invisible --convert-to docx --outdir _book $<

_book/6enanparq.odt : $(ENANPARQ_TMP) 6enanparq-sl.yaml \
	6enanparq-metadata.yaml default.opendocument reference.odt
	source .venv/bin/activate; \
	pandoc -o $@ -d spec/6enanparq-sl.yaml \
		6enanparq-intro.md 6enanparq-palazzo.tmp \
		6enanparq-florentino.tmp 6enanparq-gil_cornet.tmp \
		6enanparq-tinoco.tmp 6enanparq-metadata.yaml

%.tmp : %.md concat.yaml biblio.bib
	source .venv/bin/activate; \
	pandoc -o $@ -d spec/concat.yaml $<

# Figuras a partir de vetores {{{2
# ---------------------------

fig/%.png : %.svg
	inkscape -f $< -e $@ -d 96

# Install and cleanup {{{1
# ===================
.PHONY : link-template license clean

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
