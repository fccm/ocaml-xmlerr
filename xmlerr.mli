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
type t =
  | Tag of string * attr list  (** opening tag *)
  | ETag of string  (** closing tag *)
  | Data of string  (** PCData *)
  | Comm of string  (** Comments *)

type src = { len: unit -> int; get_char: int -> char; sub: int -> int -> string }

val string_input : string -> src
val ic_input : in_channel -> src

val parse : src -> t list
val parse_rev : src -> t list
val parse_f : 'a -> (t -> 'a -> 'a) -> src -> 'a
val parse_string : string -> t list
val parse_file : filename:string -> t list

val strip_white : t list -> t list
(** remove whitespace from beginning and ending of PCData *)

val x_lowercase : t list -> t list
(** translate tag names and attr names to lowercase *)

val print_html : t list -> unit
val print_code : t list -> unit

(**/**)
val read_file : string -> string

