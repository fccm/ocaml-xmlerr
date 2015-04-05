OCAMLC := ocamlc
OCAMLOPT := ocamlopt
DIR := xmlerr
OCAMLDIR := $(shell $(OCAMLC) -where)
DESTDIR := $(OCAMLDIR)/$(DIR)
DOCDIR := /usr/share/doc
DESTDOC := $(DOCDIR)/$(DIR)

all: cma cmxa cmxs
byte cma: xmlerr.cma
opt cmxa: xmlerr.cmxa
cmxs: xmlerr.cmxs

# Build Xmlerr

xmlerr.cmi: xmlerr.mli
	$(OCAMLC) -c $<

xmlerr.cmo: xmlerr.ml xmlerr.cmi
	$(OCAMLC) -c $<

xmlerr.cmx: xmlerr.ml xmlerr.cmi
	$(OCAMLOPT) -c $<

xmlerr.cma: xmlerr.cmo
	$(OCAMLC) -a -o $@ $<

xmlerr.cmxa: xmlerr.cmx
	$(OCAMLOPT) -a -o $@ $<

xmlerr.cmxs: xmlerr.ml
	$(OCAMLOPT) -shared $< -o $@ && strip $@

# Utils

utils: \
  xmlerr_utils.cma \
  xmlerr_utils.cmxa \
  xmlerr_utils.cmxs

xmlerr_utils.cmi: xmlerr_utils.mli
	$(OCAMLC) -c $<

xmlerr_utils.cmo: xmlerr_utils.ml xmlerr_utils.cmi
	$(OCAMLC) -c $<

xmlerr_utils.cmx: xmlerr_utils.ml xmlerr_utils.cmi
	$(OCAMLOPT) -c $<

xmlerr_utils.cma: xmlerr_utils.cmo
	$(OCAMLC) -a -o $@ $<

xmlerr_utils.cmxa: xmlerr_utils.cmx
	$(OCAMLOPT) -a -o $@ $<

xmlerr_utils.cmxs: xmlerr_utils.ml
	$(OCAMLOPT) -shared $< -o $@ && strip $@

# Test

HTML_INPUT := ./index.html
TMP_FILE := log.tmp

$(TMP_FILE): xmlerr.cmo test.ml $(HTML_INPUT)
	ocaml $^ > $@

test: $(TMP_FILE)
	cat $<

install: xmlerr.cmi
	install -d -m 755 $(DESTDIR)
	install -d -m 755 $(DESTDOC)
	install -m 644 META xmlerr.{mli,cmi} $(DESTDIR)/
	test -f xmlerr.cmo  && install -m 644 xmlerr.cmo  $(DESTDIR)/ || :
	test -f xmlerr.cma  && install -m 644 xmlerr.cma  $(DESTDIR)/ || :
	test -f xmlerr.cmx  && install -m 644 xmlerr.cmx  $(DESTDIR)/ || :
	test -f xmlerr.cmxa && install -m 644 xmlerr.cmxa $(DESTDIR)/ || :
	test -f xmlerr.cmxs && install -m 644 xmlerr.cmxs $(DESTDIR)/ || :
	install -m 644 README.txt $(DESTDOC)/

uninstall:
	rm -rf $(DESTDIR)/*
	rm -rf $(DESTDOC)/*
	rmdir $(DESTDIR)
	rmdir $(DESTDOC)

clean:
	$(RM) *.[oa] *.so *.cm[ioax] *.cmx[as] *.opt *.byte
	$(RM) $(TMP_FILE)

VERSION := $(shell date --iso)
FILES=              \
  xmlerr.ml         \
  xmlerr.mli        \
  xmlerr_utils.mli  \
  xmlerr_utils.ml   \
  Makefile          \
  test.ml           \
  README.txt        \
  index.html        \
  META              \
  #End

DIR="xmlerr-$(VERSION)"
release:
	mkdir -p $(DIR)
	cp -f $(FILES) $(DIR)/
	sed -i -e "s/@VERSION@/$(VERSION)/g" $(DIR)/META
	tar cf $(DIR).tar $(DIR)
	lzma --best $(DIR).tar
	ls -lh $(DIR).tar.lzma
	md5sum $(DIR).tar.lzma

.PHONY: clean test all release byte opt cma cmxa cmxs utils install
