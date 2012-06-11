type t

external create : ?debug:bool -> Spf_dns.t -> t = "caml_spf_server_new"
external free : t -> unit = "caml_spf_server_free"
