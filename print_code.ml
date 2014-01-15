let () =
  let xs = Xmlerr.parse_ic stdin in
  let xs = Xmlerr.strip_white xs in
  Xmlerr.print_code xs
