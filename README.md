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

## ⚠️ Heavily under construction... ⚠️

...so please do not use this anywhere in production ❗

## What

The docker images in this repository can be used with [nektos/act][nektosActRepo], which is a very
handy tool to run your github workflows locally.

If you don't know it yet, I highly recommend to check it out 🤓

## Why

In the other Images I had problems with executing azure related tools, so I decided to create my own
image which is heavily inspired by the images of [catthehacker][catthehackerImages]

## How to use

These Docker images are intended for use with nektos/arc, which allows you to run GitHub workflows
on your local host.

The easiest way is to add those lines in your `~/.actrc`:

```shell
-P ubuntu-latest=mauwii/ubuntu-act:latest
-P ubuntu-22.04=mauwii/ubuntu-act:22.04
-P ubuntu-20.04=mauwii/ubuntu-act:20.04
```

For further Informations about nektos/arc and how to use it, checkout the [nektos
documentation📖][nektosDocs]

## How I run act on my M2-Max 💻

- installed HEAD Version of act via brew

  ```bash
  brew install --HEAD act
  ```

- set an alias to always pass the GITHUB_TOKEN

  ```bash
  # always add gh auth token to act
  if validate_command act; then
      alias act='act -s GITHUB_TOKEN="$(gh auth token)"'
  # add alias to use gh act as act if gh-act is installed and act is not found
  elif gh extension list | grep -q "nektos/gh-act"; then
      alias act='gh act -s GITHUB_TOKEN="$(gh auth token)"'
  fi
  ```

> Previously I had issues when using the brew version of act, which seem to be gone 🥳
>
> But if you run into kind of the same issues, this is how I used it as a github cli extension:
>
> - didnt work properly when installed via brew, so I installed it via GitHub-CLI:
>
>   ```bash
>   gh extension install https://github.com/nektos/gh-act
>   ```
>
> - set an alias:
>
>   ```bash
>   if gh extension list | grep -q "nektos/gh-act"; then
>     alias act='gh act -s GITHUB_TOKEN="$(gh auth token)"'
>   fi
>   ```

- Docker-Desktop settings:

  - Advanced:

    ✔️ Allow the default Docker socket to be used (requires password)

  - Features in Development:

    ✔️ All Beta Features enabled (containerd, wasm, rosetta and builds view)

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
    --flavor security \  # Optional, the workflow runs the full container
    -e GITHUB_TOKEN="$(gh auth token)" \
    --remove-container
```

[dockerHub]: https://hub.docker.com/r/mauwii/ubuntu-act/ "DockerHub"
[githubRepo]: https://github.com/mauwii/act-docker-images/ "GitHub repository"
[githubFork]: https://github.com/mauwii/act-docker-images/fork/ "GitHub forks"
[githubIssues]: https://github.com/mauwii/act-docker-images/issues/ "GitHub issues"
[githubCommits]: https://github.com/mauwii/act-docker-images/commits/ "GitHub commits"
[workflowCi]: https://github.com/mauwii/act-docker-images/actions/workflows/ci.yml "ci workflow"
[workflowDhDesc]:
  https://github.com/mauwii/act-docker-images/actions/workflows/dockerhub-description.yml
  "DockerHub Description Workflow"
[workflowMegaLinter]:
  https://github.com/mauwii/act-docker-images/actions?query=workflow%3AMegaLinter+branch%3Amain
  "MegaLinter Workflow"
[nektosActRepo]: https://github.com/nektos/act "nektos/act git repository"
[catthehackerImages]:
  https://github.com/catthehacker/docker_images
  "catthehacker/docker_images repo"
[nektosDocs]: https://nektosact.com/beginner/index.html "nektos/act docs"
