#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <netinet/in.h>
#include <netinet/in.h>
#include <sys/un.h>

#include <spf2/spf.h>
#include <spf2/spf_server.h>
#include <spf2/spf_request.h>
#include <spf2/spf_response.h>
#include <spf2/spf_dns.h>
#include <spf2/spf_log.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/signals.h>
#include <caml/unixsupport.h>

#define Some_val(v)    Field(v, 0)
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
spf_error(const char *err)
{
    caml_raise_with_string(*caml_named_value("Spf.Spf_error"), err);
}

static void
finalize_spf_server(value server_val)
{
    SPF_server_t *server = (SPF_server_t *)Data_custom_val(server_val);
    SPF_server_free(server);
}

static struct custom_operations spf_server_ops = {
    "SPF_server_t custom ops",
    finalize_spf_server,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default
};

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
        caml_invalid_argument("unknown DNS type");

    server = SPF_server_new(dns_type, debug);
    if (server == NULL)
        caml_failwith("cannot create SPF server");

    server_val = caml_alloc_custom(&spf_server_ops, sizeof(*server), 0, 1);
    memcpy(Data_custom_val(server_val), server, sizeof(*server));

    CAMLreturn(server_val);
}

static void
finalize_spf_request(value req_val)
{
    SPF_request_t *req = (SPF_request_t *)Data_custom_val(req_val);
    SPF_request_free(req);
}

static struct custom_operations spf_request_ops = {
    "SPF_request_t custom ops",
    finalize_spf_request,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default
};

CAMLprim value
caml_spf_request_new(value server_val)
{
    CAMLparam1(server_val);
    CAMLlocal1(req_val);
    SPF_server_t *server = (SPF_server_t *)Data_custom_val(server_val);
    SPF_request_t *req;
    
    req = SPF_request_new(server);
    if (req == NULL)
        spf_error("cannot create SPF request");

    req_val = caml_alloc_custom(&spf_request_ops, sizeof(*req), 0, 1);
    memcpy(Data_custom_val(req_val), req, sizeof(*req));

    CAMLreturn(req_val);
}

static void
spf_get_sockaddr(value addr_val, struct sockaddr_storage *ss,
                 socklen_t *ss_len)
{
    mlsize_t len = caml_string_length(addr_val);

    switch (len) {
    case 4: {
        struct sockaddr_in *sin = (struct sockaddr_in *)ss;
        memset(sin, 0, sizeof(struct sockaddr_in));
        sin->sin_family = AF_INET;
        sin->sin_addr = (*((struct in_addr *)(addr_val)));
        *ss_len = sizeof(struct sockaddr_in);
        break;
    }
    case 16: {
        struct sockaddr_in6 *sin6 = (struct sockaddr_in6 *)ss;
        memset(sin6, 0, sizeof(struct sockaddr_in6));
        sin6->sin6_family = AF_INET6;
        sin6->sin6_addr = (*((struct in6_addr *)(addr_val)));
        *ss_len = sizeof(struct sockaddr_in6);
        break;
    }
    default:
        spf_error("unsupported address type");
    }
}

CAMLprim value
caml_spf_request_set_inet_addr(value req_val, value addr)
{
    CAMLparam2(req_val, addr);
    SPF_request_t *req = (SPF_request_t *)Data_custom_val(req_val);
    struct sockaddr_storage ss;
    socklen_t ss_len;
    SPF_errcode_t e;

    spf_get_sockaddr(addr, &ss, &ss_len);
    switch (ss.ss_family) {
    case AF_INET:
        e = SPF_request_set_ipv4(req, ((struct sockaddr_in *)&ss)->sin_addr);
        break;
    case AF_INET6:
        e = SPF_request_set_ipv6(req, ((struct sockaddr_in6 *)&ss)->sin6_addr);
        break;
    }
    if (e != SPF_E_SUCCESS)
        spf_error(SPF_strerror(e));

    CAMLreturn(Val_unit);
}

#define SPF_REQUEST_SET_STRING(name)                                \
CAMLprim value                                                      \
caml_spf_request_set_##name(value req_val, value str_val)           \
{                                                                   \
    CAMLparam2(req_val, str_val);                                   \
    SPF_request_t *req = (SPF_request_t *)Data_custom_val(req_val); \
    const char *str = String_val(str_val);                          \
    SPF_errcode_t err;                                              \
                                                                    \
    err = SPF_request_set_##name(req, str);                         \
    if (err != SPF_E_SUCCESS)                                       \
        spf_error(SPF_strerror(err));                               \
    CAMLreturn(Val_unit);                                           \
}

SPF_REQUEST_SET_STRING(ipv4_str);
SPF_REQUEST_SET_STRING(ipv6_str);
SPF_REQUEST_SET_STRING(helo_dom);
SPF_REQUEST_SET_STRING(env_from);

static inline int
tag_of_result(SPF_result_t r)
{
    switch (r) {
    case SPF_RESULT_INVALID:
        return 0;
    case SPF_RESULT_NEUTRAL:
        return 0;
    case SPF_RESULT_PASS:
        return 1;
    case SPF_RESULT_FAIL:
        return 1;
    case SPF_RESULT_SOFTFAIL:
        return 2;
    case SPF_RESULT_NONE:
        return 3;
    case SPF_RESULT_TEMPERROR:
        return 2;
    case SPF_RESULT_PERMERROR:
        return 3;
    default:
        spf_error("unexpected result");
        /* NOTREACHED */
        return -1;
    }
}

CAMLprim value
caml_spf_request_query_mailfrom(value req_val)
{
    CAMLparam1(req_val);
    CAMLlocal3(ret, cmt, res);
    SPF_request_t *req = (SPF_request_t *)Data_custom_val(req_val);
    SPF_response_t *resp;
    SPF_result_t result;

    caml_enter_blocking_section();
    SPF_request_query_mailfrom(req, &resp);
    caml_leave_blocking_section();

    ret = caml_alloc(5, 0);

    result = SPF_response_result(resp);
    res = caml_alloc(1, tag_of_result(result));

    switch (result) {
    case SPF_RESULT_FAIL:
    case SPF_RESULT_SOFTFAIL:
    case SPF_RESULT_NEUTRAL:
    case SPF_RESULT_NONE:
        cmt = caml_alloc(2, 0);
        Store_field(cmt, 0,
                    caml_copy_string(SPF_response_get_smtp_comment(resp)));
        Store_field(cmt, 1,
                    caml_copy_string(SPF_response_get_explanation(resp)));
        res = caml_alloc(1, tag_of_result(result));
        Store_field(res, 0, cmt);
        Store_field(ret, 0, res);
        break;
    case SPF_RESULT_INVALID:
    case SPF_RESULT_PASS:
    case SPF_RESULT_TEMPERROR:
    case SPF_RESULT_PERMERROR:
        Store_field(ret, 0, Val_int(tag_of_result(result)));
        break;
    }

    Store_field(ret, 1, Val_int(SPF_response_reason(resp)));
    Store_field(ret, 2, caml_copy_string(SPF_response_get_received_spf(resp)));
    Store_field(ret, 3,
                caml_copy_string(SPF_response_get_received_spf_value(resp)));
    Store_field(ret, 4,
                 caml_copy_string(SPF_response_get_header_comment(resp)));

    SPF_response_free(resp);

    CAMLreturn(ret);
}

CAMLprim value
caml_spf_strreason(value reason_val)
{
    CAMLparam1(reason_val);
    CAMLreturn(caml_copy_string(SPF_strreason(Int_val(reason_val))));
}
