type t

external create : Spf_server.t -> t = "caml_spf_request_new"
external free : t -> unit = "caml_spf_request_free"

external set_ipv4_str : t -> string -> unit =
  "caml_spf_request_set_ipv4_str"
external set_ipv6_str : t -> string -> unit =
  "caml_spf_request_set_ipv6_str"
external set_helo_domain : t -> string -> unit =
  "caml_spf_request_set_helo_dom"
external set_envelope_from : t -> string -> unit =
  "caml_spf_request_set_env_from"

external query_mailfrom : t -> Spf_response.t =
  "caml_spf_request_query_mailfrom"
