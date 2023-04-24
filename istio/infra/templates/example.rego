package istio.authz

import input.attributes.request.http as http_request

default allow = false

source_spiffe_id = spiffe_id {
	[_, _, _, uri_type_san] := split(http_request.headers["x-forwarded-client-cert"], ";")
	[_, spiffe_id] := split(uri_type_san, "=")
}

destination_spiffe_id = source_id {
	[s_id, _, _, _] := split(http_request.headers["x-forwarded-client-cert"], ";")
	[_, source_id] := split(s_id, "=")
}

allow {
	http_request.method == "GET"
	destination_spiffe_id == "spiffe://${spire_trust_domain}/workload-1"
	source_spiffe_id == "spiffe://${spire_trust_domain}/workload-2"
	http_request.path == "/version"
}

allow {
	http_request.method == "GET"
	destination_spiffe_id == "spiffe://${spire_trust_domain}/workload-2"
	source_spiffe_id == "spiffe://${spire_trust_domain}/workload-1"
	http_request.path == "/metrics"
}