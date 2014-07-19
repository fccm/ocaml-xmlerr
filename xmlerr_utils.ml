(** Utility functions *)
(* Copyright (C) 2012 Florent Monnier, Some rights reserved
  Contact: <monnier.florent(_)gmail.com>

 Permission to use, copy, modify, distribute, and sell this software and
 its documentation for any purpose is hereby granted without fee, provided
 that the above copyright notice appear in all copies and that both that
 copyright notice and this permission notice appear in supporting documentation.
 No representations are made about the suitability of this software for any
 purpose.  It is provided "as is" without express or implied warranty.
*)
open Xmlerr


let rec for_all2 p l1 l2 =
  match (l1, l2) with
  | ([], []) -> true
  | (a1::l1, a2::l2) -> p a1 a2 && for_all2 p l1 l2
  | (_, _) -> false


let cmp_attr (a1, v1) (a2, v2) =
  (a1 = a2) && (
    (v1 = v2) || (v1 = "_") || (v1 = "@")
  )


let cmp tp xs =
  let rec aux = function
  | t :: ts, x :: xs ->
      let matched =
        match t, x with
        | Data "@", Data s
        | Data "_", Data s -> true
        | Data s1, Data s2 -> (s1 = s2)
        | ETag e1, ETag e2 -> (e1 = e2)
        | Comm "@", Comm c
        | Comm "_", Comm c -> true
        | Comm c1, Comm c2 -> (c1 = c2)
        | Tag (g1, attrs1), Tag (g2, attrs2) ->
            (g1 = g2) && (for_all2 cmp_attr attrs1 attrs2)
        | _ -> false
      in
      matched && aux (ts, xs)
  | _ -> true
  in
  aux (tp, xs)


let extr_attrs attrs1 attrs2 =
  let rec aux acc = function
  | (_, "@")::t1, (_, v)::t2 -> aux (v::acc) (t1, t2)
  | _::t1, _::t2 -> aux acc (t1, t2)
  | _ -> List.rev acc
  in
  aux [] (attrs1, attrs2)


let extr tp xs =
  let rec aux acc = function
  | t :: ts, x :: xs ->
      begin match t, x with
      | Data "@", Data k
      | Comm "@", Comm k ->
          aux (k::acc) (ts, xs)
      | Data _, Data _
      | ETag _, ETag _
      | Comm _, Comm _ ->
          aux acc (ts, xs)
      | Tag (_, attrs1), Tag (_, attrs2) ->
          let ks = extr_attrs attrs1 attrs2 in
          if ks = [] then aux acc (ts, xs)
          else aux (ks @ acc) (ts, xs)
      | _ ->
          aux acc (ts, xs)
      end
  | _ -> List.rev acc
  in
  aux [] (tp, xs)


let pop n lst =
  let rec aux i lst =
    if i <= 0 then lst else
      match lst with
      | hd :: tl -> aux (pred i) tl
      | [] -> failwith "pop"
  in
  aux n lst


let extract tp xs =
  let tp_len = List.length tp in
  let rec aux acc = function
  | [] -> List.rev acc
  | (_ :: tl) as xs ->
      if cmp tp xs
      then aux ((extr tp xs) :: acc) (pop tp_len xs)
      else aux acc tl
  in
  aux [] xs


let webstr s =
  let n = String.length s in
  let b = Buffer.create n in
  let rec aux i =
    if i >= n then Buffer.contents b else
    match s.[i] with
    | '%' ->
        let sd = Printf.sprintf "0x%c%c" s.[i+1] s.[i+2] in
        let d = int_of_string sd in
        Buffer.add_char b (char_of_int d);
        aux (i+3)
    | c ->
        Buffer.add_char b c;
        aux (i+1)
  in
  aux 0
