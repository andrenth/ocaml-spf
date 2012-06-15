type t

type comments
type reason

type result
  = Invalid
  | Neutral of comments
  | Pass
  | Fail of comments
  | Softfail of comments
  | None of comments
  | Temperror
  | Permerror

val result : t -> result
val reason : t -> reason
val received_spf : t -> string
val received_spf_value : t -> string
val header_comment : t -> string
val smtp_comment : comments -> string
val explanation : comments -> string

val string_of_result : result -> string
val string_of_reason : reason -> string
