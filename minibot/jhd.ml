
type img_input =
  | Filename of string
  | Buffer of string

external f: img_input -> int * int = "caml_load_jpeg_file"

