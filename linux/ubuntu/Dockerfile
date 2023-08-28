# syntax=docker/dockerfile:1
FROM catthehacker/ubuntu:dotnet-22.04

SHELL ["/bin/bash", "--login", "-e", "-o", "pipefail", "-c"]

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && az extension add -n azure-devops \
    && az bicep install --target-platform linux-arm64 \
    && rm -rf /var/lib/apt/lists/*

# Install Github CLI
# hadolint ignore=DL3008
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0 \
    && apt-add-repository https://cli.github.com/packages \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        gh \
    && rm -rf /var/lib/apt/lists/*
