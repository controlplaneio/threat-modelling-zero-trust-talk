terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
      version = "~> 2.4"
    }
    template = {
      source = "hashicorp/template"
      version = "~> 2.2"
    }
  }
}