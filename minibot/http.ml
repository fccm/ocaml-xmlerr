
type request = GET | HEAD | POST of (string * string) list

let init_socket addr port =
  let inet_addr = (Unix.gethostbyname addr).Unix.h_addr_list.(0) in
  let sockaddr = Unix.ADDR_INET (inet_addr, port)
  and sock = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  Unix.connect sock sockaddr;
  let oc = Unix.out_channel_of_descr sock
  and ic = Unix.in_channel_of_descr sock in
  (ic, oc)

let ser_post_data post_data =
  let post_data =
    String.concat "&" (List.map (fun (key, var) -> key ^ "=" ^ var) post_data)
  in
  Printf.sprintf
    "Content-type: application/x-www-form-urlencoded\r\n\
     Content-length: %d\r\n\
     Connection: close\r\n\
     \r\n%s"
    (String.length post_data)
    post_data

let submit_request ~address ~port ~kind ~path ~referer ~user_agent =
  let req_tag, post_data =
    match kind with
    | GET -> "GET", ""
    | HEAD -> "HEAD", ""
    | POST data -> "POST", ser_post_data data
  in
  let opt_in fmt = function None -> "" | Some s -> fmt s in
  let request =
    (Printf.sprintf "%s %s HTTP/1.0\r\n" req_tag path) ^
    (Printf.sprintf "Host: %s\r\n" address) ^
    (opt_in (Printf.sprintf "User-Agent: %s\r\n") user_agent) ^
    (opt_in (Printf.sprintf "Referer: %s\r\n") referer) ^
    (post_data) ^
    ("\r\n")
  in
  let ic, oc = init_socket address port in
  output_string oc request;
  flush oc;
  (ic, oc)

let strip_cr str =
  let len = String.length str in
  let striped = String.create len in
  let get = String.unsafe_get
  and set = String.unsafe_set in
  let rec aux i j =
    if i >= len then (j) else
      if (get str i) <> '\r'
      then (set striped j (get str i); aux (succ i) (succ j))
      else aux (succ i) j
  in
  let nlen = aux 0 0 in
  (String.sub striped 0 nlen)


let cont_of_ic ?limit ic =
  let first_line = strip_cr(input_line ic) in
  let rec get_header acc =
    try
      let line = input_line ic in
      if line = "\r" || line = ""
      then acc
      else get_header(strip_cr line::acc)
    with End_of_file -> acc
  in
  let header = get_header []
  in
  let buf = Buffer.create 10240 in
  let tmp = String.make 1024 '\000' in
  let rec aux lim =
    let bytes = input ic tmp 0 (min lim 1024) in
    if bytes > 0 then begin
      Buffer.add_substring buf tmp 0 bytes;
      aux (lim - bytes)
    end
  in
  let rec aux_nolim() =
    let bytes = input ic tmp 0 1024 in
    if bytes > 0 then begin
      Buffer.add_substring buf tmp 0 bytes;
      aux_nolim()
    end
  in
  (try
     match limit with
     | Some lim -> aux lim
     | None -> aux_nolim()
   with End_of_file -> ());
  let page = Buffer.contents buf in
  (first_line, header, page)


let cut_url ~url =
  let len = String.length url in
  let address, len =
    if len < 7 then (url, len) else
    if (String.sub url 0 7) = "http://"
    then (String.sub url 7 (len - 7), (len - 7))
    else (url, len)
  in
  let address, path =
    try
      let pos = String.index address '/' in
      (String.sub address 0 pos,
       String.sub address (pos) (len - pos))
    with _ ->
      (address, "/")
  in
  (address, path)


let make_request ~url ?(port=80) ?(kind=GET) ?referer ?user_agent () =
  let address, path = cut_url ~url in
  let ic, oc = submit_request ~address ~port ~kind ~path ~referer ~user_agent in
  let cont = cont_of_ic ic in
  close_in ic;
  (cont)

