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

val parse : string -> t list
val parse_rev : string -> t list

val strip_white : t list -> t list

val x_lowercase : t list -> t list
(** translate tag names and attr names to lowercase *)

val read_file : string -> string

val print : t list -> unit
(**/**)
val print_debug : t list -> unit
