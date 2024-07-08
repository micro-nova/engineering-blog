# `engineering-blog`

This repo generates and deploys Micro-Nova's engineering blog. Posts are stored as Markdown, rendered using [Hugo](https://gohugo.io/), and deployed to an upstream object store & CDN using GitHub Actions. Infrastructure in GCP is configured using [OpenTofu](https://opentofu.org/) and stored in `opentofu/`.

## How to add a blog post

1. If you have not already, install `hugo` (might be `sudo apt install hugo`.)
1. Create the post using `hugo new post/$TITLE.md`
1. Modify the file in `content/post/$TITLE.md`.
1. Create a PR & merge it.
