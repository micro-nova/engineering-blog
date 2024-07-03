variable "env" {
  description = "The env, ie prod, dev, test"
  type        = string
}

variable "dns_name" {
  description = "The bare dns record used to instantiate various services; does not include the zone."
  type        = string
  default     = "blog"
}

variable "dns_zone_name" {
  description = "The DNS zone name in which to place the above DNS record"
  type        = string
  default     = "micro-nova.com"
}

variable "region" {
  description = "The region to deploy services into. Most things default to the provider region, but some resources need it hardcoded"
  type        = string
  default     = "us-central1"
}

variable "repo_name" {
  description = "The repo name to use for setting up OIDC auth between Github <-> Google Cloud for deploys. ex: micro-nova/support_tunnel"
  type        = string
  default     = "micro-nova/engineering-blog"
}
