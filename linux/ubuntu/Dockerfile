# syntax=docker/dockerfile:1
ARG FROM_TAG=act-22.04
ARG FROM_IMAGE=catthehacker/ubuntu
FROM ${FROM_IMAGE}:${FROM_TAG}

ARG TARGETARCH
SHELL ["/bin/bash", "--login", "-e", "-o", "pipefail", "-c"]

# install dotnet
RUN /imagegeneration/installers/dotnet.sh
ENV DOTNET_ROOT=/opt/hostedtoolcache/dotnet
ENV PATH="${PATH}:$DOTNET_ROOT"

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && az extension add -n azure-devops \
    && az bicep install --target-platform "linux-$(if [[ $(dpkg --print-architecture) == "amd64" ]]; then echo x64; else dpkg --print-architecture; fi)" \
    && rm -rf /var/lib/apt/lists/*

# install bicep-cli
RUN curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-"linux-$(if [[ $(dpkg --print-architecture) == "amd64" ]]; then echo x64; else dpkg --print-architecture; fi)" \
    && chmod +x ./bicep \
    && mv ./bicep /usr/local/bin/bicep

# Install Github CLI
# hadolint ignore=DL3008
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list >/dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*
