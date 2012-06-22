type comments =
  { explanation  : string
  ; smtp_comment : string
  }

type result
  = Invalid
  | Neutral of comments
  | Pass
  | Fail of comments
  | Softfail of comments
  | None of comments
  | Temperror
  | Permerror

type reason
  = No_reason
  | Failure
  | Localhost
  | Local_policy
  | Mech
  | Default
  | Secondary_mx

type t =
  { result             : result
  ; reason             : reason
  ; received_spf       : string
  ; received_spf_value : string
  ; header_comment     : string
  }

let string_of_result = function
  | Invalid -> "(invalid)"
  | Neutral _ -> "neutral"
  | Pass -> "pass"
  | Fail _ -> "fail"
  | Softfail _ -> "softfail"
  | None _ -> "none"
  | Temperror -> "temperror"
  | Permerror -> "permerror"

external string_of_reason : reason -> string =
  "caml_spf_strreason"

let result r = r.result
let reason r = r.reason
let received_spf r = r.received_spf
let received_spf_value r = r.received_spf_value
let header_comment r = r.header_comment

let smtp_comment c =
  c.smtp_comment

let explanation c =
  c.explanation
