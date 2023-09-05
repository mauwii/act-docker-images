# 🐳 Docker images for [nektos/act](https://github.com/nektos/act)

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
