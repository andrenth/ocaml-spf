open Printf

let () =
  Postfix.with_attrs
    (fun attrs ->
      let action = Policy.handle_attrs attrs in
      printf "action=%s\n\n%!" action)
