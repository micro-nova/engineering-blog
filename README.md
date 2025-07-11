# `engineering-blog`

This repo generates and deploys [Micro-Nova's engineering blog](https://blog.micro-nova.com). Posts are stored as Markdown, rendered using [Hugo](https://gohugo.io/), and deployed to an upstream object store & CDN using GitHub Actions. Infrastructure in GCP is configured using [OpenTofu](https://opentofu.org/) and stored in `opentofu/`. We're currently using [`hugo-ficurinia`](https://gitlab.com/gabmus/hugo-ficurinia) as the theme; check out its docs too.

## How to add a blog post

1. If you have not already, install `hugo` version v0.148.1 or later (use `sudo snap install hugo` or download the `.deb` package from [GitHub](https://github.com/gohugoio/hugo/releases))
1. Create the post using `hugo new post/$TITLE.md`
1. Modify the file in `content/post/$TITLE.md`.
1. Check out your content using `hugo server`; does everything look correct?
1. Create a PR & merge it.
