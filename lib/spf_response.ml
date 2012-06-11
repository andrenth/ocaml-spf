type t = Response_invalid
       | Response_neutral
       | Response_pass
       | Response_fail
       | Response_softfail
       | Response_none
       | Response_temperror
       | Response_permerror

let to_string = function
  | Response_invalid -> "invalid"
  | Response_neutral -> "neutral"
  | Response_pass -> "pass"
  | Response_fail -> "fail"
  | Response_softfail -> "softfail"
  | Response_none -> "none"
  | Response_temperror -> "temperror"
  | Response_permerror -> "permerror"
