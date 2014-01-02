open Xmlerr

let print_debug xs =
  let print_attrs attrs =
    List.iter (fun (key, value) ->
      Printf.printf "\n.[%s::%s]" key value) attrs
  in
  let print_x = function
  | Tag (name, attrs) ->
      print_string "(";
      print_string name;
      print_attrs attrs;
      print_string ")\n";
  | ETag (name) ->
      print_string "(#";
      print_string name;
      print_string ")\n";
  | Data d ->
      print_string "<[[\n";
      print_string d;
      print_string "\n]]>";
      print_char '\n';
  | Comm c ->
      print_string "\n=={{\n";
      print_string c;
      print_string "\n}}==\n";
  in
  List.iter print_x xs;
  print_newline()

let () =
  (*
  let s = string_input(read_file Sys.argv.(1)) in
  *)
  let s = ic_input(open_in Sys.argv.(1)) in
  let xe = strip_white(parse s) in
  print_debug xe
