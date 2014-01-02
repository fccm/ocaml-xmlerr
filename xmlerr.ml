(** xmlerr, xml parsing with error *)
(* Copyright (C) 2010 Florent Monnier, Some rights reserved
  Contact: <monnier.florent(_)gmail.com>

 Permission to use, copy, modify, distribute, and sell this software and
 its documentation for any purpose is hereby granted without fee, provided
 that the above copyright notice appear in all copies and that both that
 copyright notice and this permission notice appear in supporting documentation.
 No representations are made about the suitability of this software for any
 purpose.  It is provided "as is" without express or implied warranty.
*)

type attr = string * string
type t = Tag of string * attr list | ETag of string | Data of string | Comm of string

type src = { len: unit -> int; get_char: int -> char; sub: int -> int -> string }

let get_char = String.unsafe_get
let set_char = String.unsafe_set

let str_sub str ofs len =  (* String.unsafe_sub *)
  let s = String.create len in
  String.unsafe_blit str ofs s 0 len;
  s

let string_input str =
  let len = String.length str in
  { len = (fun () -> len);
    get_char = String.unsafe_get str;
    sub = str_sub str }

let ic_input ic =
  let len = in_channel_length ic in
  { len = (fun () -> len);
    get_char = (fun i -> seek_in ic i; input_char ic);
    sub =
      (fun ofs len ->
        seek_in ic ofs;
        let buf = String.create len in
        let got = input ic buf 0 len in
        if got = len then (buf)
        else String.sub buf 0 got)
  }

let index s i c =
  let rec aux i =
    if i = s.len() then None else
    let c' = s.get_char i in
    if c = c' then Some i
    else aux (succ i)
  in
  aux i

type p = Fst of int | Snd of int | Thd of int | Not
let index_any s i (c1, c2, c3) =
  let rec aux i =
    if i = s.len() then Not else
    let c' = s.get_char i in
    if c1 = c' then Fst i else
    if c2 = c' then Snd i else
    if c3 = c' then Thd i else
    aux (succ i)
  in
  aux i

let rec index_no_esc s i c =
  match index s i c with
  | Some i ->
      let prev = s.get_char (pred i) in
      if prev = '\\'
      then index_no_esc s (succ i) c
      else Some i
  | None -> None

let is_white = function
  | ' ' | '\n' | '\t' | '\r' -> true
  | _ -> false

let next_not_white s i =
  let rec aux i =
    if i = s.len() then None else
    match s.get_char i with
    | ' ' | '\n' | '\t' | '\r' -> aux (succ i)
    | c -> Some(c, i)
  in
  aux i

type n = End | White of int | Alt of int
let next_white_or s i c =
  let rec aux i =
    if i = s.len() then End else
    match s.get_char i with
    | ' ' | '\n' | '\t' | '\r' -> White i
    | c' ->
        if c = c' then Alt i
        else aux (succ i)
  in
  aux i

let opt_last = function "" -> None
  | s -> Some(get_char s (String.length s - 1))

let some = function Some v -> v | _ -> invalid_arg "some"


let parse_f init f s =
  let next = function
    | Some i ->
        let ni = succ i in
        if ni >= s.len() then None
        else (Some ni)
    | None -> None
  in
  let get = function
    | Some i -> Some(s.get_char i)
    | None -> None
  in

  let rec eat_white si =
    match get si with
    | Some c ->
        if is_white c
        then eat_white (next si)
        else (some si)
    | None -> pred(s.len())
  in
  let rec across_white si =
    match get si with
    | Some c ->
        if is_white c
        then across_white (next si)
        else (si)
    | None -> None
  in

  let get_attr_value si =
    let si = across_white si in
    match get si with
    | None -> ("", None)  (* err *)
    | Some ('"' as c)
    | Some ('\'' as c) ->
        let i1 = succ(some si) in
        let i2 =
          match index_no_esc s i1 c with
          | Some i -> i
          | None -> pred(s.len())
        in
        let v = s.sub i1 (i2 - i1) in
        (v, next(Some i2))
    | Some c ->  (* old fashion html *)
        let i1 = some si in
        let i2 =
          match next_white_or s i1 '>' with
          | White i -> i
          | Alt i -> i
          | End -> pred(s.len())  (* err *)
        in
        let v = s.sub i1 (i2 - i1) in
        (v, Some i2)
  in

  let rec get_attr acc i =
    match next_not_white s i with
    | None ->
        (acc, None)  (* err *)
    | Some('>', i) ->
        (acc, Some i)
    (* TODO
    | Some('/', i) ->
        begin match next_not_white s (succ i) with
        | Some('>', i) -> (acc, Some i)
        | _ -> (acc, Some i)  (* err *)
        end
    *)
    | Some(_, i1) ->
        let i2, (attr_value, si) =
          match index_any s i1 ('=', '>', ' ') with
          | Fst i -> (i, get_attr_value (next(Some i)))
          | Snd i -> (i, ("", Some i))
          | Thd i -> (i, ("", Some i))
          | Not -> (pred(s.len()), ("", None))  (* err *)
        in
        let attr_name = s.sub i1 (i2 - i1) in
        let acc = (attr_name, attr_value)::acc in
        match si with
        | Some i -> get_attr acc i
        | None ->
            (acc, si)
  in

  let get_attrs i =
    let acc, si = get_attr [] i in
    (List.rev acc, si)
  in

  let get_tag si =
    match get si with
    | None -> None
    | Some c ->
        let i1 = eat_white si in
        let i2, (attrs, si) =
          match next_white_or s i1 '>' with
          | White i -> (i, get_attrs i)
          | Alt i -> i, ([], Some i)
          | End -> pred(s.len()), ([], None)  (* err *)
        in
        let tag =
          match get (Some i1), attrs with
          | Some '/', [] ->
              let name = s.sub (i1+1) (i2 - i1 - 1) in
              ETag (name)
          | _ ->
              let name = s.sub i1 (i2 - i1) in
              Tag (name, attrs)
        in
        Some(tag, si)
  in

  let get_data si =
    let i1 = some si in
    let i2 =
      match index s i1 '<' with
      | Some i -> pred i
      | None -> pred(s.len())
    in
    let len = (1 + i2 - i1) in
    if len <= 0 then None else
      let data = s.sub i1 len in
      Some(Data data, Some i2)
  in

  let is_end_of_comment si1 =
    let si2 = next si1 in
    match get si1, get si2 with
    | Some '-', Some '>' -> Some si2
    | _ -> None
  in

  let is_comment si1 =
    let si2 = next si1 in
    let si3 = next si2 in
    match get si1, get si2, get si3 with
    | Some '!', Some '-', Some '-' -> Some(next si3)
    | _ -> None
  in

  let rec scroll_comment i =
    match index s i '-' with
    | None -> (pred(s.len()), None)  (* err *)
    | (Some i) as si ->
        match is_end_of_comment (next si) with
        | Some si -> (pred i, si)
        | None -> scroll_comment (succ i)
  in
  let get_comment si =
    match si with
    | Some i1 ->
        let i2, si = scroll_comment i1 in
        Some(s.sub i1 (i2 - i1 + 1), si)
    | None -> None
  in

  let rec list_last acc = function
    | last :: [] -> (Some last, List.rev acc)
    | x::xs -> list_last (x::acc) xs
    | [] -> None, []
  in

  (* this is a dirty fix (should find a more elegant solution) *)
  let check_closing acc = function
    | Tag(name, attrs) as tag ->
        if opt_last name = (Some '/') then 
          let sname = String.sub name 0 (String.length name - 1) in
          f (ETag sname) (f (Tag(sname, attrs)) acc)
        else begin
          match list_last [] attrs with
          | Some("/",""), attrs ->
              f (ETag name) (f (Tag(name, attrs)) acc)
          | _ -> (f tag acc)
        end
    | x -> (f x acc)
  in

  let rec loop acc si =
    match get si with
    | Some '<' ->
        begin match is_comment (next si) with
        | Some si ->
            begin match get_comment si with
            | Some(comm, si) ->
                loop (f (Comm comm) acc) (next si)
            | None -> (acc)
            end
        | None ->
            match get_tag (next si) with
            | Some(tag, si) ->
                let acc = check_closing acc tag in
                loop acc (next si)
            | None -> (acc)
        end
    | Some _ ->
        begin match get_data si with
        | Some(data, si) ->
            loop (f data acc) (next si)
        | None -> (acc)
        end
    | None -> (acc)
  in
  loop init (Some 0)

let cons x xs = x::xs
let parse_rev s = parse_f [] cons s
let parse s = List.rev(parse_rev s)
let parse_string s = parse (string_input s)

let gt = ( > )
let lt = ( < )

let strip str =
  let last = pred(String.length str) in
  let rec aux next comp i last =
    if comp i last then None else
    let c = get_char str i in
    if is_white c
    then aux next comp (next i) last
    else Some i
  in
  let i1 = aux succ gt 0 last in
  if i1 = None then None else
  let i2 = aux pred lt last 0 in
  let i1 = some i1
  and i2 = some i2 in
  let s = String.sub str i1 (i2 - i1 + 1) in
  (Some s)

let strip_white xs =
  let rec aux acc = function
  | (Data d) :: xs ->
      begin match strip d with
      | None -> aux acc xs
      | Some s -> aux ((Data s)::acc) xs
      end
  | x::xs ->
      aux (x::acc) xs
  | [] -> List.rev acc
  in
  aux [] xs

let x_lowercase =
  let rec lower_attr acc = function
    | [] -> List.rev acc
    | (field, value) :: xs ->
        let attr = (String.lowercase field, value) in
        lower_attr (attr::acc) xs
  in
  let rec aux acc = function
  | Tag (name, attrs) :: xs ->
      let name = (String.lowercase name)
      and attrs = lower_attr [] attrs in
      aux ((Tag (name, attrs)) :: acc) xs
  | ETag (name) :: xs ->
      let etag = ETag (String.lowercase name) in
      aux (etag::acc) xs
  | x::xs ->
      aux (x::acc) xs
  | [] ->
      (List.rev acc)
  in
  aux []

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
      print_string d;
      print_char '\n';
  | Comm c ->
      print_string "\n=={{\n";
      print_string c;
      print_string "\n}}==\n";
  in
  List.iter print_x xs;
  print_newline()

let print xs =
  let is_escaped s c =
    match String.length s with
    | 0 -> true
    | len ->
        let last = pred len in
        let rec aux prev i =
          if i = last then true else
          let c' = get_char s i in
          if c = c' && prev <> '\\'
          then (false)
          else aux c' (succ i)
        in
        aux s.[0] 1
  in
  let print_attrs attrs =
    List.iter (fun (key, value) ->
      let dq = String.contains value '"'
      and sq = String.contains value '\'' in
      match dq, sq with
      | false, _ -> Printf.printf " %s=\"%s\"" key value
      | _, false -> Printf.printf " %s='%s'" key value
      | _, true ->
          let dq_esc = is_escaped value '"'
          and sq_esc = is_escaped value '\'' in
          match dq_esc, sq_esc with
          | true, _ -> Printf.printf " %s=\"%s\"" key value
          | _, true -> Printf.printf " %s='%s'" key value
          | _ -> Printf.printf " %s=\"%s\"" key (String.escaped value)
    ) attrs
  in
  let rec print_x = function
  | Tag (name, attrs) :: xs ->
      print_char '<';
      print_string name;
      print_attrs attrs;
      print_char '>';
      print_x xs
  | ETag (name) :: xs ->
      print_string "</";
      print_string name;
      print_char '>';
      print_x xs
  | Data d :: xs ->
      print_string d;
      print_x xs
  | Comm c :: xs ->
      print_string "<!--";
      print_string c;
      print_string "-->";
      print_x xs
  | [] -> ()
  in
  print_x xs;
  print_newline()

let read_file f =
  let ic = open_in f in
  let n = in_channel_length ic in
  let s = String.create n in
  really_input ic s 0 n;
  close_in ic;
  (s)

let parse_file ~filename:f =
  parse_string (read_file f)
