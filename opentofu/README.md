# `opentofu/`

This folder contains [OpenTofu](https://opentofu.org/) code to deploy a basic static site.

## Setup

Install [`gcloud`](https://cloud.google.com/sdk/gcloud/) and authenticate to GCP.

Create a personal [CloudFlare API token](https://dash.cloudflare.com/profile/api-tokens); ensure it is IP-limited to the office IP and expires in <= 2 years.

Install `opentofu`, then configure a `.env` like so and `source` it:

```
export GOOGLE_CLOUD_PROJECT=$SOME_VALUE_FROM_GCP_CONSOLE
export GOOGLE_REGION=us-central1
export TF_VAR_dns_record="blog"
export TF_VAR_dns_zone_name="micro-nova.com"
export TF_VAR_env="prod"
export CLOUDFLARE_API_TOKEN="your token here"
```

## Changing infra

Please read the [OpenTofu](https://opentofu.org/docs/intro/) documentation. A sample workflow looks like this:


```
tofu plan
# does everything look okay? modify to fit
tofu apply
tofu fmt # make it pretty
# git commit & PR your changes
```
