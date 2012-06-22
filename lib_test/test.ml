open Printf

let () =
  let server = Spf_server.create Spf_dns.Dns_cache in
  let client_addr = `Ipv4_string "187.73.32.159" in
  let helo = "mta98.f1.k8.com.br" in
  let from = "andre@andrenathan.com" in
  match Spf_request.check_from server client_addr helo from with
  | `Error e ->
      printf "SPF error: %s\n%!" e
  | `Response r ->
      printf "SPF response:\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n%!"
        (Spf_response.string_of_result (Spf_response.result r))
        (Spf_response.string_of_reason (Spf_response.reason r))
        (Spf_response.received_spf r)
        (Spf_response.received_spf_value r)
        (Spf_response.header_comment r);
      match Spf_response.result r with
      | Spf_response.Neutral c
      | Spf_response.Fail c
      | Spf_response.Softfail c
      | Spf_response.None c ->
          printf "\t\t%s\n\t\t%s\n%!"
            (Spf_response.explanation c)
            (Spf_response.smtp_comment c)
      | _ -> ()

let () =
  let server = Spf_server.create ~debug:false Spf_dns.Dns_cache in
  let client_addr = `Ipv4_string "189.57.226.93" in
  let helo = "gwmail.bradescoseguros.com.br" in
  let _from = "andre@bradescoseguros.com.br" in
  match Spf_request.check_helo server client_addr helo with
  | `Error e ->
      printf "SPF error: %s\n%!" e
  | `Response r ->
      printf "SPF response:\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n%!"
        (Spf_response.string_of_result (Spf_response.result r))
        (Spf_response.string_of_reason (Spf_response.reason r))
        (Spf_response.received_spf r)
        (Spf_response.received_spf_value r)
        (Spf_response.header_comment r);
      match Spf_response.result r with
      | Spf_response.Neutral c
      | Spf_response.Fail c
      | Spf_response.Softfail c
      | Spf_response.None c ->
          printf "\t\t%s\n\t\t%s\n%!"
            (Spf_response.explanation c)
            (Spf_response.smtp_comment c)
      | _ -> ()
