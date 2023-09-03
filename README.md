# :whale: Docker images for [nektos/act](https://github.com/nektos/act)

## What

The docker images in this repository can be used with [nektos/act](https://github.com/nektos/act),
which is a very handy tool to run your github workflows locally.

If you don't know it yet, I highly recommend to check it out :neckbeard:

## Why

In the other Images I had problems with executing azure related tools, so I decided to modify a image
from [catthehacker](https://github.com/catthehacker/docker_images)

## How to use

Add this to your `~/.actrc`:

```shell
-P ubuntu-latest=mauwii/ubuntu-act:latest
-P ubuntu-22.04=mauwii/ubuntu-act:22.04
-P ubuntu-20.04=mauwii/ubuntu-act:20.04
```

For further Informations checkout the [nektos documentation:book:](https://nektosact.com/beginner/index.html)

## :warning: Could change frequently :warning:

...so please do not use this anywhere in production
