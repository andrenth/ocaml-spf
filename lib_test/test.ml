open Printf

let () =
  let server = Spf_server.create Spf_dns.Dns_cache in
  let request = Spf_request.create server in
  let client_addr = `Ipv4_string "187.73.32.159" in
  let helo = "mta98.f1.k8.com.br" in
  let from = "andre@andrenathan.com" in
  match Spf_request.check_from request client_addr helo from with
  | `Response r -> printf "SPF response: %s\n%!" (Spf_response.to_string r)
  | `Error e -> printf "SPF error: %s\n%!" e
