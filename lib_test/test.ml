open Printf

let () =
  let server = Spf_server.create Spf_dns.Dns_cache in
  let request = Spf_request.init server
    (`Ipv4_string "187.73.32.159")
    ~helo:"mta98.f1.k8.com.br"
    ~from:"andre@andrenathan.com"
    () in
  let response = Spf_request.query_mailfrom request in
  printf "SPF response: %s\n%!" (Spf_response.to_string response)
