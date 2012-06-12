type t = Invalid
       | Neutral
       | Pass
       | Fail
       | Softfail
       | None
       | Temperror
       | Permerror

let to_string = function
  | Invalid -> "invalid"
  | Neutral -> "neutral"
  | Pass -> "pass"
  | Fail -> "fail"
  | Softfail -> "softfail"
  | None -> "none"
  | Temperror -> "temperror"
  | Permerror -> "permerror"
