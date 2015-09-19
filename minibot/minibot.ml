open Xmlerr

let user_agent = "minibot"

let get_extension s =
  try
    let p = String.rindex s '.' in
    (String.sub s p (String.length s - p))
  with Not_found -> ""

let rec has_href = function
  | ("href", _) :: _ -> true
  | _::xs -> has_href xs
  | [] -> false

let rec get_href = function
  | ("href", href) :: _ -> href
  | _::xs -> get_href xs
  | [] -> invalid_arg "get_href"

let extract_links x =
  let rec aux acc = function
  | Tag ("a", attrs) :: xs
    when has_href attrs ->
      let href = get_href attrs in
      aux (href::acc) xs
  | _::xs -> aux acc xs
  | [] -> List.rev acc
  in
  aux [] x

let strip_prot url =
  let len = String.length url in
  if len < 7 then url else
  if (String.sub url 0 7) = "http://"
  then String.sub url 7 (len - 7) else 
  if len < 8 then url else
  if (String.sub url 0 8) = "https://"
  then String.sub url 8 (len - 8)
  else url

let domain s =
  let ofs =
    match (String.sub s 0 5) with
    | "http:" -> 7
    | "https" -> 8
    | _ -> 0
  in
  try
    let pos = String.index_from s ofs '/' in
    String.sub s 0 pos
  with Not_found -> s

let first_eq n this s =
  try for i = 0 to n-1 do
    if (String.unsafe_get this i) <> (String.unsafe_get s i)
    then raise Exit
  done; (true) with Exit -> (false)

let opt_first = function "" -> None | s -> Some(String.unsafe_get s 0)

let mkurl from this =
  if first_eq 4 this "http" then this else
  let sp = strip_prot from in
  match String.contains sp '/', opt_first this with
  | false, Some '/' -> (domain from) ^ this
  | false, _ -> from ^ "/" ^ this
  | true, Some '/' ->
      let pos = String.index sp '/' in
      let base = String.sub sp 0 pos in
      (base ^ this)
  | true, _ ->
      let pos = String.rindex from '/' in
      let base = String.sub from 0 pos in
      (base ^ "/" ^ this)


let test_mkurl() =
  let lst = [
    "http://www.example.com", "page.html";
    "http://www.example.com/", "page.html";
    "http://www.example.com", "/page.html";
    "http://www.example.com/", "/page.html";
    (* ================================== *)
    "http://www.example.com", "dir/page.html";
    "http://www.example.com", "/dir/page.html";
    "http://www.example.com/", "dir/page.html";
    "http://www.example.com/", "/dir/page.html";
    (* ================================== *)
    "http://www.example.com/dir/", "page.html";
    "http://www.example.com/dir/", "/page.html";
    "http://www.example.com/dir/", "./page.html";
    "http://www.example.com/dir/", "/dir2/page.html";
    "http://www.example.com/dir/", "./dir2/page.html";
    "http://www.example.com/dir/", "dir2/page.html";
    (* ================================== *)
    "http://www.example.com/dir", "page.html";
    "http://www.example.com/dir", "/page.html";
    "http://www.example.com/dir", "./page.html";
    "http://www.example.com/dir", "/dir2/page.html";
    "http://www.example.com/dir", "./dir2/page.html";
    "http://www.example.com/dir", "dir2/page.html";
    (* ================================== *)
    (* ================================== *)
    "www.example.com", "page.html";
    "www.example.com/", "page.html";
    "www.example.com", "/page.html";
    "www.example.com/", "/page.html";
    "www.example.com", "dir/page.html";
    "www.example.com", "/dir/page.html";
    "www.example.com/", "dir/page.html";
    "www.example.com/", "/dir/page.html";
    "www.example.com/dir/", "page.html";
    "www.example.com/dir/", "/page.html";
    "www.example.com/dir/", "./page.html";
    "www.example.com/dir/", "/dir2/page.html";
    "www.example.com/dir/", "./dir2/page.html";
    "www.example.com/dir/", "dir2/page.html";
    "www.example.com/dir", "page.html";
    "www.example.com/dir", "/page.html";
    "www.example.com/dir", "./page.html";
    "www.example.com/dir", "/dir2/page.html";
    "www.example.com/dir", "./dir2/page.html";
    "www.example.com/dir", "dir2/page.html";
  ] in
  List.iter (fun (from, this) ->
    Printf.printf "%s\t%s\t%s\n" from this (mkurl from this)) lst

let rec has_src = function
  | ("src", _) :: _ -> true
  | _::xs -> has_src xs
  | [] -> false

let rec get_src = function
  | ("src", src) :: _ -> src
  | _::xs -> get_src xs
  | [] -> invalid_arg "get_src"

let extract_img x =
  let rec aux acc = function
  | Tag ("img", attrs) :: xs
    when has_src attrs ->
      let src = get_src attrs in
      aux (src::acc) xs
  | _::xs -> aux acc xs
  | [] -> List.rev acc
  in
  aux [] x

let yet h url =
  if Hashtbl.mem h url then false
  else (Hashtbl.add h url (); true)

let rec crawl depth f acc flt urls =
  let h = Hashtbl.create 19 in
  let rec aux depth acc urls =
    match urls with
    | [] -> (acc)
    | url::next ->
        let referer = None in
        let _, _, cont =
          Http.make_request ~kind:Http.GET ~url ?referer ~user_agent ()
        in
        print_string "GOT: ";
        print_endline url;
        let x = Xmlerr.x_lowercase (Xmlerr.parse_string cont) in
        let links = extract_links x in
        let links = List.map (mkurl url) links in
        let links = List.filter (yet h) links in
        let links = List.filter flt links in
        aux (pred depth) (f acc url x) (next @ links)
  in
  aux depth acc urls

let str_contains s sub =
  let len = String.length s
  and slen = String.length sub
  and sub0 = sub.[0] in
  let rec aux i =
    if i >= len then false
    else begin
      if s.[i] = sub0 then
      begin
        if (String.sub s i slen) = sub then true
        else aux (succ i)
      end
      else aux (succ i)
    end
  in
  aux 0

let str_contains s sub =
  try str_contains s sub
  with _ -> false

let isnt_thumb s = not(str_contains s "thumb")
let is_jpeg_ext img =
  match get_extension img with ".jpg" | ".JPG" | ".jpeg" -> true | _ -> false

let () =
  let url = Sys.argv.(1) in
  let h = Hashtbl.create 19 in
  let g img =
    try
      let _, _, cont =
        Http.make_request ~kind:Http.GET ~url:img ~user_agent ()
      in
      if cont.[0] = '\xFF' && cont.[1] = '\xD8' then
        let width, height = Jhd.f (Jhd.Buffer cont) in
        Printf.printf ">> dims: (%d, %d) %s\n%!" width height img;
    with _ ->
      Printf.printf ">> fail: %s\n" img;
  in
  let f () url x =
    let src_imgs = extract_img x in
    let src_imgs = List.map (mkurl url) src_imgs in
    let src_imgs = List.filter (yet h) src_imgs in
    let src_imgs = List.filter is_jpeg_ext src_imgs in
    let src_imgs = List.filter isnt_thumb src_imgs in
    List.iter g src_imgs;
    ()
  in
  let d url = domain(strip_prot url) in
  let base = d url in
  let flt url = (d url) = base in
  crawl max_int f () flt [url]
