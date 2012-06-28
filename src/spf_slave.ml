open Lwt
open Printf

(* TODO configuration file *)

type config =
  { user           : string
  ; listen_address : Lwt_unix.sockaddr
  ; log_level      : Lwt_log.level
  }

let config =
  { user           = "andre"
  ; listen_address = Lwt_unix.ADDR_UNIX "/tmp/spf.socket"
  ; log_level      = Lwt_log.Debug
  }

let set_log_level level =
  Lwt_log.Section.set_level Lwt_log.Section.main level

let handle_sigterm _ =
  let log_t =
    Lwt_log.notice "got sigterm" in
  let cleanup_t =
    match config.listen_address with
    | Lwt_unix.ADDR_UNIX path -> Lwt_unix.unlink path
    | _ -> return () in
  Lwt_main.run (log_t >> cleanup_t);
  exit 0

module B = Release_buffer

let read_postfix_attrs fd =
  let siz = 1024 in
  let buf = Release_buffer.create siz in
  let rec read offset remain =
    match_lwt Release_io.read_once fd buf offset remain with
    | 0 ->
        lwt () = Lwt_log.error "got eof on socket, closing" in
        lwt () = Lwt_unix.close fd in
        return None
    | k ->
        let len = B.length buf in
        if B.get buf (len - 2) = '\n' && B.get buf (len - 1) = '\n' then
          return (Some buf)
        else
          read (offset + k) (remain - k) in
  lwt res = read 0 siz in
  return res

let parse_postfix_attrs fd =
  match_lwt read_postfix_attrs fd with
  | None ->
      return None
  | Some buf ->
      let lines = Str.split (Str.regexp "\n") (B.to_string buf) in
      return (Postfix.parse_lines lines)

let spf_server = Spf.server Spf.Dns_cache

let spf_handler fd =
  match_lwt parse_postfix_attrs fd with
  | None ->
      return ()
  | Some attrs ->
      let action = sprintf "action=%s\n\n" (Policy.handle_attrs attrs) in 
      Release_io.write fd (B.of_string action)

let main fd =
  ignore (Lwt_unix.on_signal Sys.sigterm handle_sigterm);
  Release_socket.accept_loop
    ~timeout:30.0 (* DNS lookup may be slow *)
    Lwt_unix.SOCK_STREAM
    config.listen_address
    spf_handler

let () =
  (* TODO let config = read_config_file "/etc/spfd.conf" in *)
  set_log_level config.log_level;
  Release.me ~syslog:false ~user:config.user ~main:main ()
