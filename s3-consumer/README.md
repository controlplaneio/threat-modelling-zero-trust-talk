# S3 Consumer

```puml
@startuml
left to right direction
allow_mixing

package AWS as aws <<Rectangle>> {
    object "OIDC Provider" as oidc_provider
    object "Target Bucket" as target
    object "IAM Role" as iam_role
}

package "Kind Cluster" as kind <<Rectangle>>  {
    object "S3 Consumer" as s3_consumer
    s3_consumer --() https : X.509 SVID
    object "SPIRE" as spire
}


iam_role --> target : Allow Access

s3_consumer -r-> spire : Get X.509 and JWT SVID
s3_consumer -u-> target : Get Object
s3_consumer -u-> oidc_provider : JWT SVID

oidc_provider -l-> iam_role : Identity Federation
oidc_provider --> spire : Verify JWT SVID

@enduml
```

| Name          | Description                                                                                                                    |
|---------------|--------------------------------------------------------------------------------------------------------------------------------|
| S3 Consumer   | Accesses the target bucket by exchanging a JWT SVID for temporary AWS Credentials, exposes an https interface using X.509 SVID |
| SPIRE         | Mints X.509 and JWT SVIDs for the S3 Consumer                                                                                  |
| OIDC Provider | Verifies the provided JWT SVID and returns temporary credentials based on the identity mapping to IAM Role                     |
| IAM Role      | Provides read access to the target bucket                                                                                      |
| Target Bucket | Holds the object(s) the S3 Consumer wants to access                                                                            |
