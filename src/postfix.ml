open Printf

type attrs =
  { instance       : string
  ; client_address : string
  ; helo_name      : string
  ; sender         : string
  }

module AttrMap = Map.Make(struct
  type t = string
  let compare = compare
end)

type attr_map = string AttrMap.t

let needs_attr = function
  | "instance" | "client_address" | "helo_name" | "sender" -> true
  | _ -> false

let attrs_of_map m =
  try
    let attrs =
      { instance       = AttrMap.find "instance" m
      ; client_address = AttrMap.find "client_address" m
      ; helo_name      = AttrMap.find "helo_name" m
      ; sender         = AttrMap.find "sender" m
      } in
    Some attrs
  with Not_found ->
    None

let attr k attrs =
  try
    Some (AttrMap.find k attrs)
  with Not_found ->
    None

let parse_line line =
  let re = Str.regexp "^\\([^=]+\\)=\\(.*\\)$" in
  if Str.string_match re line 0 then
    let k = Str.matched_group 1 line in
    let v = Str.matched_group 2 line in
    `Parsed (k, v)
  else if line = "" then
    `Finished
  else
    `Error

let with_attrs f =
  let attrs = ref AttrMap.empty in
  try
    while true do
      let line = input_line stdin in
      match parse_line line with
      | `Parsed (k, v) ->
          if needs_attr k then
            attrs := AttrMap.add k v !attrs
      | `Finished ->
          (match attrs_of_map !attrs with
          | None -> ()
          | Some a -> f a);
          attrs := AttrMap.empty
      | `Error ->
          ()
    done;
  with End_of_file ->
    failwith "eof"
