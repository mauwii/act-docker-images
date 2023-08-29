# syntax=docker/dockerfile:1
FROM catthehacker/ubuntu:act-22.04

ARG TARGETARCH
SHELL ["/bin/bash", "--login", "-e", "-o", "pipefail", "-c"]

# install dotnet
RUN /imagegeneration/installers/dotnet.sh

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && az extension add -n azure-devops \
    && az bicep install --target-platform "linux-$(dpkg --print-architecture)" \
    && rm -rf /var/lib/apt/lists/*

# Install Github CLI
# hadolint ignore=DL3008
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list >/dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*
