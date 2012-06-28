open Lwt
open Printf

type response
  = Dunno
  | Prepend of string
  | Defer_if_permit of string
  | Five_zero_five of string

type cache =
  { instance                 : string
  ; mutable helo_response    : Spf.response option
  ; mutable from_response    : Spf.response option
  ; mutable spf_header_added : bool
  ; mutable timestamp        : float
  }

type handler = (Spf.server -> Postfix.attrs -> cache -> response Lwt.t)

let new_cache_entry instance =
  { instance         = instance
  ; helo_response    = None
  ; from_response    = None
  ; spf_header_added = false
  ; timestamp        = Unix.time ()
  }

let string_of_response = function
  | Dunno -> "DUNNO"
  | Prepend s -> sprintf "PREPEND %s" s
  | Defer_if_permit s -> sprintf "DEFER_IF_PERMIT %s" s
  | Five_zero_five s -> sprintf "550 %s" s

let results_cache = ref None
let default_response = Dunno

let localhost_addresses =
  List.map
    (Unix.inet_addr_of_string)
    ["127.0.0.1"; "::1"]

let exempt_localhost server attrs cache =
  let addr = Postfix.client_address attrs in
  if addr <> "" && List.mem (Unix.inet_addr_of_string addr) localhost_addresses
  then
    return (Prepend "X-Comment: SPF not applicable to localhost connection")
  else
    return Dunno

let relay_addresses =
  [ "187.73.32.128/25" ]
 
let exempt_relay server attrs cache =
  let addr = Postfix.client_address attrs in
  if addr <> "" then
    let client_addr = Unix.inet_addr_of_string addr in
    let rec exempt = function
      | [] ->
          Dunno
      | relay::rest ->
          let net = Network.of_string relay in
          if Network.includes client_addr net then
            Prepend "X-Comment: SPF skipped for whitelisted relay"
          else
            exempt rest in
    return (exempt relay_addresses)
  else
    return Dunno

let unbox_spf_response = function
  | `Error e -> failwith (sprintf "error: %s" e)
  | `Response r -> r

let some = function
  | None -> failwith "Option.some: None value"
  | Some x -> x

let may_default z f = function
  | None -> z
  | Some x -> f x

let fail_on_helo_temperror = true

let handle_helo_response sender cache =
  let res = some cache.helo_response in
  match Spf.result res with
  | Spf.Fail comment ->
      Five_zero_five (Spf.smtp_comment comment)
  | Spf.Temperror ->
      if fail_on_helo_temperror then
        let comment = Spf.header_comment res in
        Defer_if_permit (sprintf "SPF-Result=%s" comment)
      else
        Dunno
  | _ ->
      if sender = "" && not cache.spf_header_added then begin
        cache.spf_header_added <- true;
        let expl = match Spf.result res with
        | Spf.Neutral c | Spf.Fail c
        | Spf.Softfail c ->
            sprintf " %s" (Spf.smtp_comment c)
        | _ ->
            "" in
        Prepend (sprintf "%s%s" (Spf.received_spf res) expl)
      end else
        Dunno

let handle_from_response cache =
  let res = some cache.from_response in
  match Spf.result res with
  | Spf.Fail comment ->
      Five_zero_five (Spf.explanation comment)
  | Spf.Temperror ->
      let comment = Spf.header_comment res in
      Defer_if_permit (sprintf "SPF-Result=%s" comment)
  | _ ->
      if not cache.spf_header_added then begin
        cache.spf_header_added <- true;
        let expl = match Spf.result res with
        | Spf.Neutral c | Spf.Fail c
        | Spf.Softfail c ->
            sprintf " %s" (Spf.explanation c)
        | _ ->
            "" in
        Prepend (sprintf "%s%s" (Spf.received_spf res) expl)
      end else
        Dunno

let check_helo server addr helo =
  Lwt_preemptive.detach (fun () -> Spf.check_helo server addr helo) ()

let process_helo spf_server client_addr helo_name sender cache =
  lwt () = if cache.helo_response = None then begin
    lwt res = check_helo spf_server client_addr helo_name in
    let res' = unbox_spf_response res in
    cache.helo_response <- Some res';
    return ()
  end else
    return () in
  return (handle_helo_response sender cache)

let check_from server addr helo sender =
  Lwt_preemptive.detach (fun () -> Spf.check_from server addr helo sender) ()

let process_from spf_server client_addr helo_name sender cache =
  lwt () = if cache.from_response = None then begin
    lwt res = check_from spf_server client_addr helo_name sender in
    let res = unbox_spf_response res in
    cache.from_response <- Some res;
    return ()
  end else
    return () in
  return (handle_from_response cache)

let sender_policy_framework spf_server attrs cache =
  let client_addr = Postfix.client_address attrs in
  let helo_name = Postfix.helo_name attrs in
  let sender = Postfix.sender attrs in
  let addr = Unix.inet_addr_of_string client_addr in
  match_lwt process_helo spf_server addr helo_name sender cache with
  | Dunno -> process_from spf_server addr helo_name sender cache
  | other -> return other

let handlers =
  [ exempt_localhost
  ; exempt_relay
  ; sender_policy_framework
  ]

let rec until p f z = function
  | [] ->
      return z
  | h::t ->
      lwt x = f h in
      if p x then return x else until p f z t

let get_cache instance =
  match !results_cache with
  | None ->
      let cache = new_cache_entry instance in
      results_cache := Some cache;
      cache
  | Some cache ->
      if cache.instance = instance then begin
        cache
      end else begin
        let cache = new_cache_entry instance in
        results_cache := Some cache;
        cache
      end

let handle_attrs spf_server attrs =
  let cache = get_cache (Postfix.instance attrs) in
  let not_default = ((<>) default_response) in
  lwt response =
    until not_default
      (fun handler -> handler spf_server attrs cache)
      default_response
      handlers in
  return (string_of_response response)

let lookup_timeout =
  string_of_response (Defer_if_permit "SPF-Result=Timeout handling SPF lookup")
