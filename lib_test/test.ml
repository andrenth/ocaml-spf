open Printf

let () =
  let server = Spf_server.create Spf_dns.Dns_cache in
  let request = Spf_request.create server in
  Spf_request.set_ipv4_str request "187.73.32.159";
  Spf_request.set_helo_domain request "mta98.f1.k8.com.br";
  Spf_request.set_envelope_from request "andre@andrenathan.com";
  let response = Spf_request.query_mailfrom request in
  printf "SPF response: %s\n%!" (Spf_response.to_string response)
