open Printf

type attrs =
  { instance       : string
  ; client_address : string
  ; helo_name      : string
  ; sender         : string
  }

let instance attrs = attrs.instance
let client_address attrs = attrs.client_address
let helo_name attrs = attrs.helo_name
let sender attrs = attrs.sender

module AttrMap = Map.Make(struct
  type t = string
  let compare = compare
end)

type attr_map = string AttrMap.t

let new_attr_map = AttrMap.empty
let add_addr = AttrMap.add

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

let parse_lines lines =
  let map = List.fold_left
    (fun map line ->
      match parse_line line with
      | `Error -> map
      | `Finished -> map
      | `Parsed (k, v) -> if needs_attr k then AttrMap.add k v map else map)
    AttrMap.empty
    lines in
  attrs_of_map map
