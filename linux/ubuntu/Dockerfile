# syntax=docker/dockerfile:1
ARG FROM_IMAGE
ARG FROM_FLAVOR
ARG FROM_VERSION
FROM --platform=$TARGETPLATFORM ${FROM_IMAGE}:${FROM_FLAVOR}-${FROM_VERSION}

# add build arguments
ARG TARGETARCH
ARG FROM_VERSION

# set default shell to bash with pipefail and no profile
SHELL ["/bin/bash", "--noprofile", "-e", "-o", "pipefail", "-c"]

# create targetproc file for later use
RUN export targetarch=${TARGETARCH} \
    && if [ ${targetarch} = "amd64" ]; then export targetarch="x64"; fi \
    && echo ${targetarch} >/tmp/targetproc

# install .NET SDK LTS
ENV DOTNET_ROOT=${AGENT_TOOLSDIRECTORY}/dotnet
ENV PATH=${DOTNET_ROOT}:${PATH}
ENV DOTNET_GENERATE_ASPNET_CERTIFICATE=false
ENV DOTNET_NOLOGO=true
ENV DOTNET_SDK_VERSION=6.0.413
ENV DOTNET_USE_POLLING_FILE_WATCHER=true
ENV NUGET_XMLDOC_MODE=skip
# hadolint ignore=DL3008
RUN export fromVersion=${FROM_VERSION} \
    && deps=("libc6" "libgcc1" "libgssapi-krb5-2" "libstdc++6" "zlib1g") \
    && if [ "${fromVersion}" = "20.04" ]; then deps+=("libicu66" "libssl1.1"); fi \
    && if [ "${fromVersion}" = "22.04" ]; then deps+=("libicu70" "libssl3" "libunwind8"); fi \
    && apt-get update && apt-get install -y --no-install-recommends --no-upgrade "${deps[@]}" \
    && curl -L https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh \
    && chmod +x ./dotnet-install.sh \
    && ./dotnet-install.sh \
        --install-dir "${DOTNET_ROOT}" \
        --no-path \
        --channel LTS \
        --version "${DOTNET_SDK_VERSION}" \
    && rm -rf ./dotnet-install.sh \
    && rm -rf /var/lib/apt/lists/* \
    && dotnet --info

# Install PowerShell global tool
RUN export powershell_version=7.2.13 \
    && curl -fSL \
        --output PowerShell.Linux."$(cat /tmp/targetproc)".$powershell_version.nupkg \
        https://pwshtool.blob.core.windows.net/tool/$powershell_version/PowerShell.Linux."$(cat /tmp/targetproc)".$powershell_version.nupkg \
    && mkdir -p /usr/share/powershell \
    && dotnet tool install \
        --add-source / \
        --tool-path /usr/share/powershell \
        --version $powershell_version \
        PowerShell.Linux."$(cat /tmp/targetproc)" \
    && dotnet nuget locals all --clear \
    && rm PowerShell.Linux."$(cat /tmp/targetproc)".$powershell_version.nupkg \
    && ln -s /usr/share/powershell/pwsh /usr/bin/pwsh \
    && chmod 755 /usr/share/powershell/pwsh \
    && find /usr/share/powershell -print | grep -i '.*[.]nupkg$' | xargs rm

# # Install Azure Powershell Modules
RUN export azVersion=10.2.0 \
    && pwsh \
        -NonInteractive \
        -NoProfile \
        -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted" \
    && pwsh \
        -NonInteractive \
        -NoProfile \
        -Command "Install-Module -Name Az -RequiredVersion ${azVersion} -Scope AllUsers -Repository PSGallery"

# Install Github CLI
# hadolint ignore=DL3008
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$TARGETARCH signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list >/dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
# hadolint ignore=DL3008
RUN [[ $(curl -sL https://packages.microsoft.com/repos/azure-cli/dists/) =~ $(lsb_release -cs) ]] \
    && (curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >/etc/apt/trusted.gpg.d/microsoft.gpg \
        && echo "deb [arch=$(dpkg --print-architecture)] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
            >/etc/apt/sources.list.d/azure-cli.list \
        && apt-get update \
        && apt-get install -y --no-install-recommends azure-cli \
        && az extension add -n azure-devops \
        && az bicep install --target-platform "linux-$(cat /tmp/targetproc)" \
        && az config set bicep.use_binary_from_path=true \
        && az config set auto-upgrade.enable=no \
        && az config set auto-upgrade.prompt=no \
        && az config set core.collect_telemetry=false \
        && rm -rf /var/lib/apt/lists/*) \
    || echo "Azure CLI not available for this distribution"

# install bicep-cli
RUN curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-"$(cat /tmp/targetproc)" \
    && chmod +x ./bicep \
    && mv ./bicep /usr/local/bin/bicep

# clean tmp
RUN rm -Rf /tmp/*
