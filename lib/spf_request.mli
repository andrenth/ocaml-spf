type t

exception Spf_request_error of string

val create : Spf_server.t -> t

val free : t -> unit

val check_helo : Spf_server.t
              -> Unix.inet_addr
              -> string
              -> [`Response of Spf_response.t | `Error of string]

val check_from : Spf_server.t
              -> Unix.inet_addr
              -> string
              -> string
              -> [`Response of Spf_response.t | `Error of string]
