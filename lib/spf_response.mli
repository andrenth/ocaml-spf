type t
  = Response_invalid
  | Response_neutral
  | Response_pass
  | Response_fail
  | Response_softfail
  | Response_none
  | Response_temperror
  | Response_permerror

val to_string : t -> string
