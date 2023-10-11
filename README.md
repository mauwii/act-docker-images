# 🐳 Docker images for [nektos/act](https://github.com/nektos/act)

[![Docker Pulls](https://badgen.net/docker/pulls/mauwii/ubuntu-act?icon=docker&label=pulls)][dockerHub]
[![Docker Image Size](https://badgen.net/docker/size/mauwii/ubuntu-act?icon=docker&label=image%20size)][dockerHub]
[![Docker Stars](https://badgen.net/docker/stars/mauwii/ubuntu-act?icon=docker&label=stars)][dockerHub]
[![Github stars](https://badgen.net/github/stars/mauwii/act-docker-images?icon=github&label=stars)][githubRepo]
[![Github forks](https://badgen.net/github/forks/mauwii/act-docker-images?icon=github&label=forks)][githubFork]
[![Github issues](https://badgen.net/github/issues/mauwii/act-docker-images/?icon=github&label=issues)][githubIssues]
[![Github last-commit](https://badgen.net/github/last-commit/mauwii/act-docker-images/?color=blue&icon=github&label=last-commit)][githubCommits]

[![ci](https://github.com/mauwii/act-docker-images/actions/workflows/ci.yml/badge.svg?branch=main&event=push)][workflowCi]
[![MegaLinter](https://github.com/mauwii/act-docker-images/workflows/MegaLinter/badge.svg?branch=main&event=push)][workflowMegaLinter]
[![Docker-Hub description](https://github.com/mauwii/act-docker-images/actions/workflows/dockerhub-description.yml/badge.svg?branch=main)][workflowDhDesc]

> [!WARNING]  
> Heavily under construction, so please do not use this anywhere in production

## What

The docker images in this repository are made to be used with [nektos/act][nektosActRepo], which is
a very handy tool to execute github workflows locally.

If you don't know it yet, I highly recommend to check it out 🤓

## Why

In the other Images I had problems with executing azure related tools, so I decided to create my own
image which is heavily inspired by the images of [catthehacker][catthehackerImages] and the
[official runner images][actionsRunnerImages].

## How to use

These Docker images are intended for use with nektos/arc, which allows you to run GitHub workflows
on your local host.

The easiest way is to add those lines in your `~/.actrc`:

```bash
-P ubuntu-latest=mauwii/ubuntu-act:latest
-P ubuntu-22.04=mauwii/ubuntu-act:22.04
-P ubuntu-20.04=mauwii/ubuntu-act:20.04
```

For further information about [nektos/act][nektosActRepo] and how to use it, take a 👀 at the
[nektos documentation📖][nektosDocs]

## How I run act on my M2-Max 💻

- Install act via [brew🍺](https://brew.sh)

  ```bash
  brew install act
  ```

  > [!IMPORTANT]  
  > Use `act --version` to make sure you have at least `act version 0.2.51`, which came with support
  > for node20

- set an alias to always pass the GITHUB_TOKEN (requires github-cli (`brew install gh`))

  ```bash
  if command -v act >/dev/null 2>&1; then
      alias act='act -s GITHUB_TOKEN="$(gh auth token)"'
  elif gh extension list | grep -q "nektos/gh-act"; then
      alias act='gh act -s GITHUB_TOKEN="$(gh auth token)"'
  fi
  ```

- 🐳 Docker-Desktop settings:

  - Docker Engine (`~/.docker/daemon.json`):

    ```json
    {
      "builder": {
        "gc": {
          "defaultKeepStorage": "20GB",
          "enabled": true
        }
      },
      "experimental": true,
      "features": {
        "buildkit": true
      }
    }
    ```

  - Features in Development:

    - ❌ containerd
    - ❌ wasm
    - ✅ rosetta
    - ✅ builds view

  - Advanced:
    - ❌ system
    - ✅ user
    - ✅ Allow the default Docker socket to be used
    - ❌ Allow privileged port mapping
    - ✅ Automatically check configuration

- `~/.actrc`:

  ```bash
  --rm
  -P ubuntu-latest=mauwii/ubuntu-act:latest
  -P ubuntu-22.04=mauwii/ubuntu-act:22.04
  -P ubuntu-20.04=mauwii/ubuntu-act:20.04
  ```

## docker-bake file

As always, there are different options to build the images locally. I added `docker-bake.hcl` which
helps with orchestrating builds but needs buildx to be available on the host (it comes out of the
box with docker desktop).

> [!WARNING]  
> Bake Files are still considered experimental, and your results may be totally different depending
> on your local docker configuration.

- using the `local` tag:

  ```bash
  docker buildx bake \
      --set "*.platform=linux/$(uname -m)"
  ```

- using the current branch as a tag name and set better labels, without pushing the cache to the
  registry:

  ```bash
  GITHUB_SHA="$(git rev-parse HEAD)" \
  REF_NAME="$(git rev-parse --abbrev-ref HEAD)" \
  docker buildx bake \
      --set="*.cache-to=" \
      --set="*.platform=linux/$(uname -m)"
  ```

  When you do this from the main branch and already use the latest image, it will be replaced with
  the one you just built.

If you are not using a mac silicon, just replace the platform `arm64` with `amd64`.

## mega-linter

To execute the mega-linter locally without the needs to install it, there are different options:

- you can use act (I assume you run act the way I just explained):

  ```bash
  act -W .github/workflows/mega-linter.yml
  ```

  This has the advantage that megalinter executes with the same settings as the workflow itself,
  while not providing fixed versions if errors where found.

- or you could use npx:

  ```bash
  npx mega-linter-runner \
      --flavor terraform \
      -e GITHUB_TOKEN="$(gh auth token)" \
      --remove-container
  ```

## Pre-Commit-Hook

I integrated a pre-commit hook to run mega-linter. There are different ways to install pre-commit on
your system. I used brew since I am working on MacOS (`brew install pre-commit`). Another easy way
would be via pipx.

After successfully installing pre-commit on your system, you need to run `pre-commit install` in the
repository root if you want to enable the pre-commit hooks on your system as well.

[dockerHub]: https://hub.docker.com/r/mauwii/ubuntu-act/ "DockerHub container repository"
[githubRepo]: https://github.com/mauwii/act-docker-images/ "GitHub repository"
[githubFork]: https://github.com/mauwii/act-docker-images/fork/ "GitHub repository - forks"
[githubIssues]: https://github.com/mauwii/act-docker-images/issues/ "GitHub repository - issues"
[githubCommits]: https://github.com/mauwii/act-docker-images/commits/ "GitHub repository - commits"
[workflowCi]:
  https://github.com/mauwii/act-docker-images/actions/workflows/ci.yml
  "GitHub workflow - ci"
[workflowDhDesc]:
  https://github.com/mauwii/act-docker-images/actions/workflows/dockerhub-description.yml
  "DockerHub Description Workflow"
[workflowMegaLinter]:
  https://github.com/mauwii/act-docker-images/actions?query=workflow%3AMegaLinter+branch%3Amain
  "MegaLinter Workflow"
[nektosActRepo]: https://github.com/nektos/act "nektos/act git repository"
[nektosDocs]: https://nektosact.com/beginner/index.html "nektos/act docs"
[catthehackerImages]:
  https://github.com/catthehacker/docker_images
  "catthehacker/docker_images repo"
[actionsRunnerImages]: https://github.com/actions/runner-images "official GitHub Runner images"
