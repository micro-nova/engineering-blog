# `micro-nova-engineering-blog`

This repo generates and deploys Micro-Nova's engineering blog. Posts are stored as Markdown, rendered using Hugo, and deployed to an upstream object store (presently in GCP.)

## prereqs

Install these prereqs:
```
apt install hugo
```

## How to add a blog post

1. Create the post using `hugo new post/$TITLE.md`
1. Modify the file in `content/post/$TITLE.md`.
1. Create a PR & merge it.


