type t

val create : ?debug:bool -> Spf_dns.t -> t
val free : t -> unit
