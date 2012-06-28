open Lwt
open Printf

(* TODO configuration file *)
let spf_exec = sprintf "%s/_build/src/spf-slave" (Unix.getcwd ())
let lock_file = "/tmp/spfd.pid"
let num_slaves = 4
let listen_socket = "/tmp/spf.socket" 
let spf_ipc_handler fd = return ()

let () =
  Release.master_slave
    ~background:false
    ~syslog:false
    ~lock_file:lock_file
    ~slave:(spf_exec, spf_ipc_handler)
    ()
