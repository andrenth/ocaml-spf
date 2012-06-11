type t

exception Spf_request_error of string

let _ = Callback.register_exception
  "Spf_request.Spf_request_error"
  (Spf_request_error "")

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

let init server ip ?helo ?from () =
  let req = create server in
  (match ip with
  | `Ipv4_string s -> set_ipv4_str req s
  | `Ipv6_string s -> set_ipv6_str req s);
  Option.may (set_helo_domain req) helo;
  Option.may (set_envelope_from req) from;
  req
