---
title: "Supporting our users"
date: 2024-06-19T15:01:57-04:00
draft: true
author: Ryan
---

AmpliPi is a software project created by Micro-Nova as a smart whole-home amplifier and audio system. We have been developing [AmpliPi (software)](https://github.com/micro-nova/AmpliPi)/[AmpliPro(hardware)](https://www.amplipro.com/) since 2019 and launched with a [Kickstarter in 2021](https://www.kickstarter.com/projects/micro-nova/amplipi-home-audio-system). We take pride in our product being open source, privacy preserving by default, extensible and audiophile quality; we develop all of the software and hardware in house, right outside Detroit, Michigan.

With this ethos, our userbase has tended to share our values. They are often highly technical folks, who care a great deal about privacy but also tinker for fun. They've contributed to our codebase {cite}, created neat integrations with various other services {cite}, and notably contribute extremely detailed bug reports {cite}. We're extremely grateful to our users and try to do good by them always.

However, with our successes, our potential userbase has opened up quite a bit. AmpliPro is now being sold commercially across the world to users with various technical skillsets and in as varied of contexts as custom houses, offices, and even boats. With our values intact but our userbase growing, we have some difficult problems to solve. {one more question here} How do we trend towards bulletproof quality without engaging in less-than-consensual data collection? How can we examine technical problems first-hand, when a user cannot contribute `systemd` logs or even knows what `ssh` is... but without installing a forever-on backdoor?

Enter [support_tunnel](https://github.com/micro-nova/support_tunnel), our implementation of an extremely secure, open source, remote connection capability. `support_tunnel` is intended for us to troubleshoot issues remotely over SSH with a deep emphasis on user consent and privacy. At its core, this software helps instantiate [WireGuard](https://www.google.com/search?client=firefox-b-1-e&q=wireguard) tunnels between a remote device (in this case an AmpliPro) and an ephemerally launched server in the cloud, used as an intermediary between our engineers and a customer box. This software also runs an API in the cloud to act as an always-on bookkeeper for requesting a support tunnel and storing various details. We've published all the source for this implementation and licensed it as GPLv3 - [contact us](sales@micro-nova.com) if you'd like to relicense it or for software/implementation support.

We had a couple of constraints in designing this system:
* It must use as many existing network and crypto primitives as possible
* It must emphasize user consent and device security every step along the way
* It must be performant and cost-effective


