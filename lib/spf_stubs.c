#include <netinet/in.h>

#include <spf2/spf.h>
#include <spf2/spf_server.h>
#include <spf2/spf_request.h>
#include <spf2/spf_response.h>
#include <spf2/spf_dns.h>
#include <spf2/spf_log.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/signals.h>

#define Some_val(v)    Field(v,0)
#define Val_none       Val_int(0)

static int
dns_type_of_val(value v)
{
    switch (Int_val(v)) {
    case 0:
        return SPF_DNS_RESOLV;
    case 1:
        return SPF_DNS_CACHE;
    case 2:
        return SPF_DNS_ZONE;
    default:
        return -1;
    }
}

static void
spf_error(const char *s)
{
    CAMLlocal2(exn, msg);

    exn = alloc_small(2, 0);
    msg = caml_copy_string(s);
    Field(exn, 0) = *caml_named_value("Spf.Spf_error");
    Field(exn, 1) = msg;
    caml_raise(exn);
}

CAMLprim value
caml_spf_server_new(value debug_val, value dns_type_val)
{
    CAMLparam2(debug_val, dns_type_val);
    CAMLlocal1(server_val);
    int debug;
    int dns_type;
    SPF_server_t *server;

    debug = (debug_val == Val_none) ? 0 : Bool_val(Some_val(debug_val));

    dns_type = dns_type_of_val(dns_type_val);
    if (dns_type == -1)
        spf_error("unknown DNS type");

    server = SPF_server_new(dns_type, debug);
    if (server == NULL)
        spf_error("cannot create SPF server");

    CAMLreturn((value)server);
}

CAMLprim value
caml_spf_server_free(value server_val)
{
    CAMLparam1(server_val);
    SPF_server_t *server = (SPF_server_t *)server_val;
    SPF_server_free(server);
    CAMLreturn(Val_unit);
}

CAMLprim value
caml_spf_request_new(value server_val)
{
    CAMLparam1(server_val);
    SPF_server_t *server = (SPF_server_t *)server_val;
    SPF_request_t *req;
    
    req = SPF_request_new(server);
    if (req == NULL)
        spf_error("cannot create SPF request");

    CAMLreturn((value)req);
}

CAMLprim value
caml_spf_request_free(value req_val)
{
    CAMLparam1(req_val);
    SPF_request_t *req = (SPF_request_t *)req_val;
    SPF_request_free(req);
    CAMLreturn(Val_unit);
}

#define SPF_REQUEST_SET_STRING(name)                      \
CAMLprim value                                            \
caml_spf_request_set_##name(value req_val, value str_val) \
{                                                         \
    CAMLparam2(req_val, str_val);                         \
    SPF_request_t *req = (SPF_request_t *)req_val;        \
    const char *str = String_val(str_val);                \
    SPF_errcode_t err;                                    \
                                                          \
    err = SPF_request_set_##name(req, str);               \
    if (err != 0)                                         \
        spf_error(SPF_strerror(err));                     \
    CAMLreturn(Val_unit);                                 \
}

SPF_REQUEST_SET_STRING(ipv4_str);
SPF_REQUEST_SET_STRING(ipv6_str);
SPF_REQUEST_SET_STRING(helo_dom);
SPF_REQUEST_SET_STRING(env_from);

CAMLprim value
caml_spf_request_query_mailfrom(value req_val)
{
    CAMLparam1(req_val);
    CAMLlocal1(res);
    SPF_request_t *req = (SPF_request_t *)req_val;
    SPF_response_t *resp;
    SPF_errcode_t err;

    err = SPF_request_query_mailfrom(req, &resp);
    if (err != 0)
        spf_error(SPF_strerror(err));

    res = Val_int(SPF_response_result(resp));
    SPF_response_free(resp);

    CAMLreturn(res);
}
