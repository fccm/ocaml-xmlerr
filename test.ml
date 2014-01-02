open Xmlerr

let () =
  let s = read_file Sys.argv.(1) in
  let xe = strip_white(parse s) in
  print_debug xe
