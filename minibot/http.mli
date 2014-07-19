type request = GET | HEAD | POST of (string * string) list

val make_request :
  url:string ->
  ?port:int ->
  ?kind:request ->
  ?referer:string ->
  ?user_agent:string ->
    unit ->
      string * string list * string
