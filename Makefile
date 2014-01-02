DIR := xmlerr
OCAMLDIR := $(shell ocamlc -where)
DESTDIR := $(OCAMLDIR)/$(DIR)
DOCDIR := /usr/share/doc
DESTDOC := $(DOCDIR)/$(DIR)

all: byte opt
byte: xmlerr.cmo
opt: xmlerr.cmx
cma: xmlerr.cma
cmxa: xmlerr.cmxa


xmlerr.cmi: xmlerr.mli
	ocamlc -c $<

xmlerr.cmo: xmlerr.ml xmlerr.cmi
	ocamlc -c $<

xmlerr.cmx: xmlerr.ml xmlerr.cmi
	ocamlopt -c $<

xmlerr.cma: xmlerr.cmo
	ocamlmklib $< -o xmlerr

xmlerr.cmxa: xmlerr.cmx
	ocamlmklib $< -o xmlerr

xmlerr.cmxs: xmlerr.ml
	ocamlopt -shared $< -o $@ && strip $@

HTML := ./index.html
TMP_FILE := log.tmp

$(TMP_FILE): xmlerr.cmo test.ml $(HTML)
	ocaml $^ > $@

test: $(TMP_FILE)
	vim $< $(HTML)

install: xmlerr.cmi
	install -d -m 755 $(DESTDIR)
	install -d -m 755 $(DESTDOC)
	install -m 644 META xmlerr.{mli,cmi} $(DESTDIR)/
	test -f xmlerr.cmo  && install -m 644 xmlerr.cmo  $(DESTDIR)/ || :
	test -f xmlerr.cma  && install -m 644 xmlerr.cma  $(DESTDIR)/ || :
	test -f xmlerr.cmo  && install -m 644 xmlerr.cmo  $(DESTDIR)/ || :
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
	rm -f *.[oa] *.so *.cm[ioax] *.cmx[as] *.opt *.byte
	rm -f $(TMP_FILE)

.PHONY: clean test all byte opt install
