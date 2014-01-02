open Xmlerr

let () =
  (*
  let s = string_input(read_file Sys.argv.(1)) in
  *)
  let s = ic_input(open_in Sys.argv.(1)) in
  let xe = strip_white(parse s) in
  print_debug xe
