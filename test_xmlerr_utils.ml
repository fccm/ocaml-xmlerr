let () =
  let xs = Xmlerr.parse_file "lst.html" in
  let tp = Xmlerr.parse_file "tmpl.html" in
  let xs = Xmlerr.strip_white xs in
  let tp = Xmlerr.strip_white tp in
  let lst = Xmlerr_utils.extract tp xs in
  List.iter (fun pats ->
    print_endline (String.concat "\t" pats)
  ) lst
