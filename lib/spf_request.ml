type request

type t =
  { request : request
  ; server  : Spf_server.t
  }

exception Spf_request_error of string

let _ = Callback.register_exception
  "Spf_request.Spf_request_error"
  (Spf_request_error "")

external spf_request_new : Spf_server.t -> request = "caml_spf_request_new"

external spf_request_free : request -> unit = "caml_spf_request_free"

external request_set_inet_addr : request -> Unix.inet_addr -> unit =
  "caml_spf_request_set_inet_addr"

external request_set_ipv4_str : request -> string -> unit =
  "caml_spf_request_set_ipv4_str"

external request_set_ipv6_str : request -> string -> unit =
  "caml_spf_request_set_ipv6_str"

external request_set_helo_domain : request -> string -> unit =
  "caml_spf_request_set_helo_dom"

external request_set_envelope_from : request -> string -> unit =
  "caml_spf_request_set_env_from"

external query_mailfrom : request -> Spf_response.t =
  "caml_spf_request_query_mailfrom"

let create server =
  let req = spf_request_new server in
  { request = req; server = server }

let free req =
  spf_request_free req.request

let set_inet_addr req ip =
  request_set_inet_addr req.request ip

let set_ipv4_str req ip =
  request_set_ipv4_str req.request ip

let set_ipv6_str req ip =
  request_set_ipv6_str req.request ip

let set_helo_domain req domain =
  request_set_helo_domain req.request domain

let set_envelope_from req from =
  request_set_envelope_from req.request from

let process req =
  try
    `Response (query_mailfrom req.request)
  with Spf_request_error err ->
    `Error err

let check_helo server client_addr helo =
  let req = create server in
  set_inet_addr req client_addr;
  set_helo_domain req helo;
  let ret = process req in
  free req;
  ret

let check_from server client_addr helo from =
  let req = create server in
  set_inet_addr req client_addr;
  set_helo_domain req helo;
  set_envelope_from req from;
  let ret = process req in
  free req;
  ret
