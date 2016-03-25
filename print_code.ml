let () =
  let url = Sys.argv.(1) in
  let statut_line, header, page =
    Http.make_request ~url ()
  in
  let xs = Xmlerr.parse_string page in
  let xs = Xmlerr.strip_white xs in
  print_endline statut_line;
  List.iter print_endline header;
  Xmlerr.print_code xs
