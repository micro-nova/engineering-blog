data "github_repository" "repo" {
  full_name = var.repo_name
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-${data.github_repository.repo.name}-${var.env}"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "Github"
  description                        = "OIDC identity pool provider for automated deployments from Github -> Cloud Run"
  attribute_condition                = "assertion.repository_owner == 'micro-nova' && assertion.repository_id == '${data.github_repository.repo.repo_id}'"
  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.repository_id"    = "assertion.repository_id"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "github" {
  account_id   = "${data.github_repository.repo.name}-${var.env}"
  display_name = "Service account used for deploying new Docker images from github"
}

resource "google_service_account_iam_binding" "github" {
  service_account_id = google_service_account.github.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${data.github_repository.repo.full_name}"
  ]
}

resource "google_project_iam_custom_role" "static_site_cdn" {
  role_id     = "${var.dns_name}_${var.env}_cdn"
  title       = "invalidate CDN for static site, ${data.github_repository.repo.name}-${var.env}"
  description = "Limited scope role for github to deploy the static site"
  permissions = [
    "compute.urlMaps.get",
    "compute.urlMaps.invalidateCache",
  ]
}

resource "google_project_iam_binding" "static_site_cdn" {
  project = data.google_project.project.project_id
  role    = google_project_iam_custom_role.static_site_cdn.name
  members = [
    "serviceAccount:${google_service_account.github.email}"
  ]
}

resource "google_project_iam_custom_role" "static_site_bucket" {
  role_id     = "${var.dns_name}_${var.env}_bucket"
  title       = "deploy static site to bucket, ${data.github_repository.repo.name}-${var.env}"
  description = "Limited scope role for github to deploy the static site"
  permissions = [
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.getIamPolicy",
    "storage.objects.list",
    "storage.objects.update",
  ]
}


resource "google_project_iam_binding" "static_site_bucket" {
  project = data.google_project.project.project_id
  role    = google_project_iam_custom_role.static_site_bucket.name
  members = [
    "serviceAccount:${google_service_account.github.email}"
  ]

  condition {
    title      = "only_static_bucket_contents"
    expression = "resource.name.startsWith('projects/_/buckets/${google_storage_bucket.static_site.name}')"
  }
}


resource "github_repository_environment" "repo" {
  repository  = data.github_repository.repo.name
  environment = var.env
}

resource "github_actions_environment_secret" "oidc_workload_provider" {
  repository      = data.github_repository.repo.name
  environment     = github_repository_environment.repo.environment
  secret_name     = "WORKLOAD_IDENTITY_PROVIDER"
  plaintext_value = google_iam_workload_identity_pool_provider.github.name
}

resource "github_actions_environment_secret" "project_id" {
  repository      = data.github_repository.repo.name
  environment     = github_repository_environment.repo.environment
  secret_name     = "PROJECT_ID"
  plaintext_value = data.google_project.project.project_id
}

resource "github_actions_environment_secret" "deploy_service_account" {
  repository      = data.github_repository.repo.name
  environment     = github_repository_environment.repo.environment
  secret_name     = "DEPLOY_SERVICE_ACCOUNT"
  plaintext_value = google_service_account.github.email
}
