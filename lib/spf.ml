exception Spf_error of string

let _ = Callback.register_exception "Spf.Spf_error" (Spf_error "")
