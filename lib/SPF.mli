type server

type dns = Dns_resolv
         | Dns_cache
         | Dns_zone

type request
type response

type comments
type reason

type result
  = Invalid
  | Neutral of comments
  | Pass
  | Fail of comments
  | Softfail of comments
  | None
  | Temperror
  | Permerror

exception SPF_error of string

val server : ?debug:bool -> dns -> server

val request : server -> request

val check_helo : server
              -> Unix.inet_addr
              -> string
              -> [`Response of response | `Error of string]

val check_from : server
              -> Unix.inet_addr
              -> string
              -> string
              -> [`Response of response | `Error of string]

val result : response -> result
val reason : response -> reason
val received_spf : response -> string
val received_spf_value : response -> string
val header_comment : response -> string
val smtp_comment : comments -> string
val explanation : comments -> string

val string_of_result : result -> string
val string_of_reason : reason -> string