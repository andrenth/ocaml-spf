type t

exception Spf_request_error of string

val create : Spf_server.t -> t

val init : Spf_server.t
        -> [`Ipv4_string of string | `Ipv6_string of string]
        -> ?helo:string
        -> ?from:string
        -> unit -> t

val free : t -> unit

val set_ipv4_str : t -> string -> unit
val set_ipv6_str : t -> string -> unit
val set_helo_domain : t -> string -> unit
val set_envelope_from : t -> string -> unit

val query_mailfrom : t -> Spf_response.t
