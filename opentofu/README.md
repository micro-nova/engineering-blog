# `opentofu/`

This folder contains [OpenTofu](https://opentofu.org/) code to deploy a basic static site.

## Setup

Install opentofu, then configure a `.env` like so and `source` it:

```
export GOOGLE_CLOUD_PROJECT=$SOME_VALUE_FROM_GCP_CONSOLE
export GOOGLE_REGION=us-central1
export TF_VAR_dns_record="blog"
export TF_VAR_dns_zone_name="micro-nova.com"
export TF_VAR_env="prod"
export CLOUDFLARE_API_TOKEN="your token here" # create a cloudflare token that is IP limited to the office and expires in 2yrs
```
