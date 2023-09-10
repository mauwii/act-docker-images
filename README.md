# 🐳 Docker images for [nektos/act](https://github.com/nektos/act)

[![Docker Pulls](https://badgen.net/docker/pulls/mauwii/ubuntu-act?icon=docker&label=pulls)](https://hub.docker.com/r/mauwii/ubuntu-act/)
[![Docker Image Size](https://badgen.net/docker/size/mauwii/ubuntu-act?icon=docker&label=image%20size)](https://hub.docker.com/r/mauwii/ubuntu-act/)
[![Docker Stars](https://badgen.net/docker/stars/mauwii/ubuntu-act?icon=docker&label=stars)](https://hub.docker.com/r/mauwii/ubuntu-act/)
[![Github stars](https://badgen.net/github/stars/mauwii/act-docker-images?icon=github&label=stars)](https://github.com/mauwii/act-docker-images)
[![Github forks](https://badgen.net/github/forks/mauwii/act-docker-images?icon=github&label=forks)](https://github.com/mauwii/act-docker-images/fork)
[![Github issues](https://badgen.net/github/issues/mauwii/act-docker-images/?icon=github&label=issues)](https://github.com/mauwii/act-docker-images/issues)
[![Github last-commit](https://badgen.net/github/last-commit/mauwii/act-docker-images/?color=blue&icon=github&label=last-commit)](https://github.com/mauwii/act-docker-images/commits/)

[![ci](https://github.com/mauwii/act-docker-images/actions/workflows/ci.yml/badge.svg?branch=main&event=push)](https://github.com/mauwii/act-docker-images/actions/workflows/ci.yml)
[![Docker-Hub description](https://github.com/mauwii/act-docker-images/actions/workflows/dockerhub-description.yml/badge.svg?branch=main)](https://github.com/mauwii/act-docker-images/actions/workflows/dockerhub-description.yml)
[![MegaLinter](https://github.com/mauwii/act-docker-images/workflows/MegaLinter/badge.svg?branch=main)](https://github.com/mauwii/act-docker-images/actions?query=workflow%3AMegaLinter+branch%3Amain)

## ⚠️ Heavily under construction... ⚠️

...so please do not use this anywhere in production ❗

## What

The docker images in this repository can be used with [nektos/act](https://github.com/nektos/act),
which is a very handy tool to run your github workflows locally.

If you don't know it yet, I highly recommend to check it out 🤓

## Why

In the other Images I had problems with executing azure related tools, so I decided to create my own
image which is heavily inspired by the images of
[catthehacker](https://github.com/catthehacker/docker_images)

## How to use

These Docker images are intended for use with nektos/arc, which allows you to run GitHub workflows
on your local host.

The easiest way is to add those lines in your `~/.actrc`:

```shell
-P ubuntu-latest=mauwii/ubuntu-act:latest
-P ubuntu-22.04=mauwii/ubuntu-act:22.04
-P ubuntu-20.04=mauwii/ubuntu-act:20.04
```

For further Informations about nektos/arc and how to use it, checkout the
[nektos documentation📖](https://nektosact.com/beginner/index.html)

## How I run act on my M2-Max 💻

- didnt work properly when installed via brew, so I installed it via GitHub-CLI:

  ```bash
  gh extension install https://github.com/nektos/gh-act
  ```

- set an alias:

  ```bash
  alias act='gh act -s GITHUB_TOKEN="$(gh auth token)"'
  ```

- export DOCKER_HOST env

  ```bash
  DOCKER_HOST=$(docker context inspect --format '{{.Endpoints.docker.Host}}')
  export DOCKER_HOST
  ```

- Docker-Desktop settings:

  - Advanced:

    ✔️ Allow the default Docker socket to be used (requires password)

  - Features in Development:

    ✔️ All Beta Features enabled (containerd, wasm, rosetta and builds view)

- `~/.actrc`:

  ```text
  --container-architecture linux/arm64
  -P ubuntu-latest=mauwii/ubuntu-act:latest
  -P ubuntu-22.04=mauwii/ubuntu-act:22.04
  -P ubuntu-20.04=mauwii/ubuntu-act:20.04
  ```

## mega-linter

To execute the mega-linter locally:

```bash
npx mega-linter-runner \
    --flavor salesforce \
    -e GITHUB_TOKEN="$(gh auth token)" \
    --remove-container
```
