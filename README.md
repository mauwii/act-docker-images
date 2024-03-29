# 🐳 Docker images for [nektos/act](https://github.com/nektos/act)

[![Docker Pulls][DockerHub-pulls-badge]][DockerHub]
[![Docker Image Size][DockerHub-size-badge]][DockerHub]
[![Docker Stars][DockerHub-stars-badge]][DockerHub]
[![Github stars][GitHub-stars-badge]][GitHub-Repo]
[![Github forks][GitHub-forks-badge]][GitHub-Fork]
[![Github issues][GitHub-issues-badge]][GitHub-Issues]
[![Github last-commit][GitHub-commit-badge]][GitHub-Commits]

[![ci workflow badge][ci-badge]][Workflow-ci] [![MegaLinter][MegaLinter-badge]][Workflow-MegaLinter]
[![Docker-Hub description workflow badge][Docker-Hub-description-badge]][Workflow-DockerHubDescription]
[![Mergify badge][mergify-badge]][mergify] [![License badge][License-badge]][License]

## What

The containers in this repository are made to be used with [nektos/act][nektos-act-repo], which is a
very handy tool to execute, test and debug github workflows locally.

If you don't know it yet, I highly recommend to check it out 🤓

## Why

Since I had trouble with other images when executing azure related tools, I decided to create my own
container which is heavily inspired by the images of [catthehacker][catthehacker-image-repo] and the
[official runner images][actions-runner-images].

## How to use

These Docker images are intended to be used with [nektos/act][nektos-act-repo]. Setup guides can be
found [here][nektosSetupGuide].

Add these lines in `~/.actrc` to use this image with act:

```bash
-P ubuntu-latest=mauwii/ubuntu-act:latest
-P ubuntu-22.04=mauwii/ubuntu-act:22.04
-P ubuntu-20.04=mauwii/ubuntu-act:20.04
```

For further information about [nektos/act][nektos-act-repo] and how to use it, take a 👀 at the
[nektos documentation📖][nektosDocs]

## How to run act on apple silicon 💻

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
  --container-architecture linux/arm64
  --rm=true
  --reuse=false
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
      --remove-container
  ```

## Pre-Commit-Hook

I integrated a pre-commit hook to run mega-linter. There are different ways to install pre-commit on
your system. I used brew since I am working on MacOS (`brew install pre-commit`). Another easy way
would be via pipx.

After successfully installing pre-commit on your system, you need to run `pre-commit install` in the
repository root if you want to enable the pre-commit hooks on your system as well.

<!-- links -->

[DockerHub]: https://hub.docker.com/r/mauwii/ubuntu-act/ "DockerHub container repository"
[GitHub-Repo]: https://github.com/mauwii/act-docker-images/ "GitHub repository"
[GitHub-Fork]: https://github.com/mauwii/act-docker-images/fork/ "GitHub repository - forks"
[GitHub-Issues]: https://github.com/mauwii/act-docker-images/issues/ "GitHub repository - issues"
[GitHub-Commits]: https://github.com/mauwii/act-docker-images/commits/ "GitHub repository - commits"
[License]: https://github.com/mauwii/act-docker-images/blob/main/LICENSE "License"
[nektos-act-repo]: https://github.com/nektos/act "nektos/act git repository"
[nektosSetupGuide]: https://nektosact.com/installation/index.html "nektos/act setup guide"
[nektosDocs]: https://nektosact.com/introduction.html "nektos/act docs"
[catthehacker-image-repo]:
  https://github.com/catthehacker/docker_images
  "catthehacker/docker_images repo"
[actions-runner-images]: https://github.com/actions/runner-images "official GitHub Runner images"
[Workflow-ci]:
  https://github.com/mauwii/act-docker-images/actions/workflows/ci.yml
  "GitHub workflow - ci"
[Workflow-DockerHubDescription]:
  https://github.com/mauwii/act-docker-images/actions/workflows/dockerhub-description.yml
  "GitHub workflow - DockerHub Description"
[Workflow-MegaLinter]:
  https://github.com/mauwii/act-docker-images/actions?query=workflow%3AMegaLinter+branch%3Amain
  "GitHub workflow - MegaLinter"
[mergify]: https://mergify.com "Mergify.com"

<!-- badges -->

[mergify-badge]:
  https://img.shields.io/endpoint.svg?url=https://api.mergify.com/v1/badges/mauwii/act-docker-images&style=flat
[ci-badge]:
  https://github.com/mauwii/act-docker-images/actions/workflows/ci.yml/badge.svg?branch=main&event=push
[MegaLinter-badge]:
  https://github.com/mauwii/act-docker-images/workflows/MegaLinter/badge.svg?branch=main&event=push
[Docker-Hub-description-badge]:
  https://github.com/mauwii/act-docker-images/actions/workflows/dockerhub-description.yml/badge.svg?branch=main
[DockerHub-pulls-badge]: https://badgen.net/docker/pulls/mauwii/ubuntu-act?icon=docker&label=pulls
[DockerHub-size-badge]:
  https://badgen.net/docker/size/mauwii/ubuntu-act?icon=docker&label=image%20size
[DockerHub-stars-badge]: https://badgen.net/docker/stars/mauwii/ubuntu-act?icon=docker&label=stars
[GitHub-stars-badge]: https://badgen.net/github/stars/mauwii/act-docker-images?icon=github
[GitHub-forks-badge]: https://badgen.net/github/forks/mauwii/act-docker-images?icon=github
[GitHub-issues-badge]: https://badgen.net/github/issues/mauwii/act-docker-images/?icon=github
[GitHub-commit-badge]:
  https://badgen.net/github/last-commit/mauwii/act-docker-images/main?icon=github&color=blue
[License-badge]: https://badgen.net/github/license/mauwii/act-docker-images
