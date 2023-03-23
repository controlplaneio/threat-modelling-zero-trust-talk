data "external" "thumbprint" {
  program = [
    "python",
    "${path.module}/thumbprint.py",
  ]

  query = {
    host = local.spire_trust_domain
  }
}
