open Printf
open Util

type spf_result
 = Response of Spf.response
 | Whitelisted of string
 | No_result
 

type priv =
  { spf_server         : Spf.server
  ; addr               : Unix.inet_addr option
  ; mutable helo       : string
  ; mutable from       : string
  ; mutable is_auth    : bool
  ; mutable spf_result : spf_result
  }

let default_priv =
  { spf_server = Spf.server Spf.Dns_cache
  ; addr       = None
  ; helo       = ""
  ; from       = ""
  ; is_auth    = false
  ; spf_result = No_result
  }

let config = Config.default

let unbox_spf = function
  | `Error e -> failwith (sprintf "error: %s" e)
  | `Response r -> r

let canonicalize a =
  let e = String.length a - 1 in
  let a = if a.[0] = '<' && a.[e] = '>' then String.sub a 1 (e-1) else a in
  let a = if a.[0] = '"' && a.[e] = '"' then String.sub a 1 (e-1) else a in
  let e = String.length a - 1 in
  try
    let t = String.rindex a '@' in
    let u = String.sub a 0 (t) in
    let d = String.sub a (t+1) (e-t) in
    let u = if u.[0] = '"' && u.[t-1] = '"' then String.sub u 1 (t-2) else u in
    try
      let v = String.rindex u ':' in
      let u = String.sub u (v+1) (String.length u - v - 1) in
      u ^ "@" ^ d
    with Not_found ->
      u ^ "@" ^ d
  with Not_found ->
    a

let milter_reject ctx comment =
  Milter.setreply ctx "550" (Some "5.7.1") (Some comment);
  Milter.Reject

let milter_tempfail ctx comment =
  Milter.setreply ctx "451" (Some "4.7.1") (Some comment);
  Milter.Tempfail

let spf_check_helo ctx priv =
  let addr = some (priv.addr) in
  let helo = priv.helo in
  let res = unbox_spf (Spf.check_helo priv.spf_server addr helo) in
  priv.spf_result <- Response res;
  match Spf.result res with
  | Spf.Fail c ->
      milter_reject ctx (Spf.smtp_comment c)
  | Spf.Temperror ->
      if config.Config.fail_on_helo_temperror then
        milter_tempfail ctx (Spf.header_comment res)
      else
        Milter.Continue
  | _ ->
      Milter.Continue

let spf_check_from ctx priv =
  let addr = some (priv.addr) in
  let helo = priv.helo in
  let from = priv.from in
  let res = unbox_spf (Spf.check_from priv.spf_server addr helo from) in
  priv.spf_result <- Response res;
  match Spf.result res with
  | Spf.Fail c -> milter_reject ctx (Spf.smtp_comment c)
  | Spf.Temperror -> milter_tempfail ctx (Spf.header_comment res)
  | _ -> Milter.Continue

let spf_check ctx priv =
  match spf_check_helo ctx priv with
  | Milter.Continue -> spf_check_from ctx priv
  | other -> other

let spf_add_header ctx header =
  let sep = String.index header ':' in
  let field = String.sub header 0 sep in
  let value = String.sub header (sep + 2) (String.length header - sep - 2) in
  Milter.addheader ctx field value

let with_priv_data ctx f =
  match Milter.getpriv ctx with
  | None ->
      invalid_arg "no private data"
  | Some priv ->
      let r = f priv in
      Milter.setpriv ctx priv;
      r

module FlagSet = SetOfList(struct
  type t = Milter.flag
  let compare = compare
end)

module StepSet = SetOfList(struct
  type t = Milter.step
  let compare = compare
end)

(* Callbacks *)

let connect ctx host addr =
  let addr = default Unix.inet_addr_loopback inet_addr_of_sockaddr addr in
  let spf_result =
    default No_result (fun s -> Whitelisted s) (Whitelist.check addr) in
  let priv =
    { default_priv with
      addr       = Some addr
    ; spf_result = spf_result
    } in
  Milter.setpriv ctx priv;
  Milter.Continue

let helo ctx helo =
  match helo with
  | None ->
      Milter.setreply ctx "503" (Some "5.0.0") (Some "Please say HELO");
      Milter.Reject
  | Some name ->
      with_priv_data ctx
        (fun priv ->
          priv.helo <- name;
          Milter.Continue)

let envfrom ctx from args =
  with_priv_data ctx
    (fun priv ->
      let auth = Milter.getsymval ctx "{auth_authen}" in
      let verif = default false ((=)"OK") (Milter.getsymval ctx "{verify}") in
      if auth <> None || verif then begin
        priv.is_auth <- true;
        priv.spf_result <- Whitelisted ("X-Comment: authenticated client");
        Milter.Continue
      end else begin
        priv.from <- canonicalize from;
        match priv.spf_result with
        | No_result -> spf_check ctx priv
        | _ -> Milter.Continue (* whitelisted *)
      end)

let eom ctx =
  let priv = some (Milter.getpriv ctx) in
  (match priv.spf_result with
  | No_result -> ()
  | Whitelisted s -> spf_add_header ctx s
  | Response r -> spf_add_header ctx (Spf.received_spf r));
  Milter.Continue

let abort ctx =
  match Milter.getpriv ctx with
  | None ->
      Milter.Continue
  | Some priv ->
      let priv' =
        { default_priv with
          addr = priv.addr
        ; helo = priv.helo
        } in
      Milter.setpriv ctx priv';
      Milter.Continue

let close ctx =
  match Milter.getpriv ctx with
  | None ->
      Milter.Continue
  | Some _ ->
      Milter.setpriv ctx default_priv;
      Milter.Continue

let negotiate ctx actions steps =
  let reqactions = [Milter.ADDHDRS] in
  if FlagSet.subset (FlagSet.of_list reqactions) (FlagSet.of_list actions) then
    let noreqsteps =
      StepSet.of_list
        [ Milter.NORCPT
        ; Milter.NOHDRS
        ; Milter.NOEOH
        ; Milter.NOBODY
        ; Milter.NOUNKNOWN
        ; Milter.NODATA
        ] in
    let steps = StepSet.of_list steps in
    let noreqsteps = StepSet.elements (StepSet.inter steps noreqsteps) in
    (Milter.Continue, reqactions, noreqsteps)
  else
    (Milter.Reject, [], [])
