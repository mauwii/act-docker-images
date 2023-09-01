# syntax=docker/dockerfile:1
ARG FROM_IMAGE
ARG FROM_FLAVOR
ARG FROM_VERSION
FROM --platform=$TARGETPLATFORM ${FROM_IMAGE}:${FROM_FLAVOR}-${FROM_VERSION}

# add build arguments
ARG TARGETARCH
ARG FROM_VERSION

# set default shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# SHELL ["/bin/bash", "--no-profile", "-e", "-o", "pipefail", "-c"]

# install dotnet
ENV DOTNET_ROOT=/opt/hostedtoolcache/dotnet
ENV PATH="$PATH:$DOTNET_ROOT"
RUN curl -LO https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.sh \
    && bash ./dotnet-install.sh --install-dir "${DOTNET_ROOT}" --no-path --channel STS \
    && rm ./dotnet-install.sh

# Install Powershell
ARG POWERSHELL_VERSION=7.3.6
ENV DOTNET_TOOLS=/${DOTNET_ROOT}/tools
RUN curl -L -o packages-microsoft-prod.deb "https://packages.microsoft.com/config/ubuntu/${FROM_VERSION}/packages-microsoft-prod.deb" \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && if ! apt-get install -y --no-install-recommends powershell=${POWERSHELL_VERSION}*; then dotnet tool install --tool-path ${DOTNET_TOOLS} --no-cache --version ${POWERSHELL_VERSION} powershell; fi \
    && rm -rf /var/lib/apt/lists/*
ENV PATH="${PATH}:${DOTNET_TOOLS}"

# # Install Azure Powershell Module v10.2.0
# RUN pwsh -Command Set-PSRepository -Name PSGallery -InstallationPolicy Trusted \
#     && pwsh -Command Install-Module -Name Az -RequiredVersion 10.2.0 -Scope AllUsers

# Install Github CLI
# hadolint ignore=DL3008
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$TARGETARCH signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list >/dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && az extension add -n azure-devops \
    && az bicep install --target-platform "linux-$(if [[ ${TARGETARCH} == "amd64" ]]; then echo x64; else echo ${TARGETARCH}; fi)" \
    && az config set bicep.use_binary_from_path=true \
    && rm -rf /var/lib/apt/lists/*

# install bicep-cli
RUN curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-"$(if [[ ${TARGETARCH} == "amd64" ]]; then echo x64; else echo ${TARGETARCH}; fi)" \
    && chmod +x ./bicep \
    && mv ./bicep /usr/local/bin/bicep
