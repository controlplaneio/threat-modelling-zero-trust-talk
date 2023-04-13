# Istio

```puml
@startuml

package "Kind Cluster" as kind <<Rectangle>>  {
    object "Workload" as workload
    object "OPA" as opa
    object "Istio" as istio
    
    object "SPIRE" as spire
    object Kyverno
}

istio -d-> spire : Get X.509 SVID

workload <-r-> istio
istio -r-> opa : Eternal Authz

@enduml
```

| Name     | Description                                                                        |
|----------|------------------------------------------------------------------------------------|
| Workload | Uses the Istio sidecar for network communication                                   |
| Istio    | Proxies network requests and checks with OPA whether the request should be allowed |
| OPA      | Provides AuthZ decisions to Istio                                                  |
| SPIRE    | Mints X.509 SVIDs for Istio                                                        |
| Kyverno  | Injects Istio and OPA sidecars into workload pods                                  |
