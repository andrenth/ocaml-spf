type t
  = Invalid
  | Neutral
  | Pass
  | Fail
  | Softfail
  | None
  | Temperror
  | Permerror

val to_string : t -> string
