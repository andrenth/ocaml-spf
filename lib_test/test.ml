open Printf

let () =
  let server = Spf.server Spf.Dns_cache in
  let client_addr = Unix.inet_addr_of_string "187.73.32.159" in
  let helo = "mta98.f1.k8.com.br" in
  let from = "andre@andrenathan.com" in
  match Spf.check_from server client_addr helo from with
  | `Error e ->
      printf "SPF error: %s\n%!" e
  | `Response r ->
      printf "SPF response:\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n%!"
        (Spf.string_of_result (Spf.result r))
        (Spf.string_of_reason (Spf.reason r))
        (Spf.received_spf r)
        (Spf.received_spf_value r)
        (Spf.header_comment r);
      match Spf.result r with
      | Spf.Neutral c
      | Spf.Fail c
      | Spf.Softfail c ->
          printf "\t\t%s\n\t\t%s\n%!"
            (Spf.explanation c)
            (Spf.smtp_comment c)
      | _ -> ()

let () =
  let server = Spf.server ~debug:false Spf.Dns_cache in
  let client_addr = Unix.inet_addr_of_string "189.57.226.93" in
  let helo = "gwmail.bradescoseguros.com.br" in
  let _from = "andre@bradescoseguros.com.br" in
  match Spf.check_helo server client_addr helo with
  | `Error e ->
      printf "SPF error: %s\n%!" e
  | `Response r ->
      printf "SPF response:\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n%!"
        (Spf.string_of_result (Spf.result r))
        (Spf.string_of_reason (Spf.reason r))
        (Spf.received_spf r)
        (Spf.received_spf_value r)
        (Spf.header_comment r);
      match Spf.result r with
      | Spf.Neutral c
      | Spf.Fail c
      | Spf.Softfail c ->
          printf "\t\t%s\n\t\t%s\n%!"
            (Spf.explanation c)
            (Spf.smtp_comment c)
      | _ -> ()
