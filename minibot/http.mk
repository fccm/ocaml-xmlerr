all: byte opt
byte: http.cmo
opt: http.cmx

http.cmi: http.mli
	ocamlc -c $<

http.cmo: http.ml http.cmi
	ocamlc -c $<

http.cmx: http.ml http.cmi
	ocamlopt -c $<

.PHONY: all byte opt
