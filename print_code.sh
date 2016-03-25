cd `dirname $0`

#XMLERR_DIR="$HOME/xmlerr"
XMLERR_DIR="./"

ocaml \
  -I $XMLERR_DIR xmlerr.cma \
  unix.cma \
  -I ./minibot/ http.cmo \
  print_code.ml $*
