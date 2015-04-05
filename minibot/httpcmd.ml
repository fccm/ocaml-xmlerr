#load "unix.cma"
#load "http.cmo"

let () =
  let argl = Array.to_list Sys.argv in
  let print kind url =
    let a, b, c = Http.make_request ~url ~kind () in
    print_endline "================";
    print_endline a;
    print_endline "================";
    List.iter print_endline b;
    print_endline "================";
    print_endline c;
    print_endline "================";
  in
  let rec loop = function
  | "get"::url::[] -> print Http.GET url
  | "head"::url::[] -> print Http.HEAD url
  | _::tl -> loop tl
  | _ -> ()
  in
  loop argl

