DIR := xmlerr
OCAMLDIR := $(shell ocamlc -where)
DESTDIR := $(OCAMLDIR)/$(DIR)

all: byte opt
byte: xmlerr.cmo
opt: xmlerr.cmx

xmlerr.cmi: xmlerr.mli
	ocamlc -c $<

xmlerr.cmo: xmlerr.ml xmlerr.cmi
	ocamlc -c $<

xmlerr.cmx: xmlerr.ml xmlerr.cmi
	ocamlopt -c $<

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
	install -m 644 META xmlerr.{mli,cmi} $(DESTDIR)/
	test -f xmlerr.cmo  && install -m 644 xmlerr.cmo  $(DESTDIR)/ || :
	test -f xmlerr.cmx  && install -m 644 xmlerr.cmx  $(DESTDIR)/ || :
	test -f xmlerr.cmxs && install -m 644 xmlerr.cmxs $(DESTDIR)/ || :

clean:
	rm -f *.[oa] *.cm[ioax] *.{cmxa,cmxs,opt,byte}
	rm -f $(TMP_FILE)

.PHONY: clean test all byte opt install
