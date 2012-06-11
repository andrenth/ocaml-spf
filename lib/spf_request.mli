type t

val create : Spf_server.t -> t
val free : t -> unit

val set_ipv4_str : t -> string -> unit
val set_ipv6_str : t -> string -> unit
val set_helo_domain : t -> string -> unit
val set_envelope_from : t -> string -> unit

val query_mailfrom : t -> Spf_response.t
