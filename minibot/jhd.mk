OCAMLC = ocamlc.opt
OCAMLOPT = ocamlopt.opt
OCAMLMKLIB = ocamlmklib

.PHONY: byte opt all
byte: jhd.cma
opt: jhd.cmxa
all: byte opt

jhd.cmi jhd.cmo: jhd.ml
	$(OCAMLC) -c $<

jhd.cmx jhd.o: jhd.ml
	$(OCAMLOPT) -c $<

jhd_stubs.o: jhd_stubs.c
	$(OCAMLC) -c $<

dlljhd_stubs.so libjhd_stubs.a: jhd_stubs.o
	$(OCAMLMKLIB) -o jhd $< -L"`ocamlc -where`" -ljpeg

jhd.cmxa jhd.a:  jhd.cmx  dlljhd_stubs.so
	$(OCAMLMKLIB) -o jhd $< -L"`ocamlc -where`" -ljpeg

jhd.cma:  jhd.cmo  dlljhd_stubs.so
	$(OCAMLMKLIB) -o jhd $< -L"`ocamlc -where`" -ljpeg

