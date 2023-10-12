# syntax=docker/dockerfile:1
# kics-scan disable=e36d8880-3f78-4546-b9a1-12f0745ca0d5,965a08d7-ef86-4f14-8792-4a3b2098937e,77783205-c4ca-4f80-bb80-c777f267c547,0008c003-79aa-42d8-95b8-1c2fe37dbfe6
ARG FROM_VERSION=22.04
FROM buildpack-deps:${FROM_VERSION} as base

# Force apt to not be interactive/not ask
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt to always assume Y
RUN echo "APT::Get::Assume-Yes \"true\";" >/etc/apt/apt.conf.d/90assumeyes

# set locale
ARG language=en_US
RUN apt-get -y update >/dev/null \
    && apt-get -y install --no-install-recommends \
        locales \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/* \
    && localedef \
        --inputfile="${language}" \
        --force \
        --charmap=UTF-8 \
        --alias-file=/usr/share/locale/locale.alias "${language}.UTF-8"
ENV LANG=${language}.utf8 \
    LANGUAGE=${language} \
    LC_ALL=${language}.utf8 \
    RUNNER_MANUALLY_TRAP_SIG=1 \
    ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1

FROM base as golang
ARG TARGETARCH
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
ENV PATH=/usr/local/go/bin:${PATH}
ARG GOLANG_SHA256_amd64=cc97c28d9c252fbf28f91950d830201aa403836cbed702a05932e63f7f0c7bc4
ARG GOLANG_SHA256_arm64=15ab379c6a2b0d086fe3e74be4599420e66549edf7426a300ee0f3809500f89e
ARG GOLANG_VERSION=1.20.8
RUN mkdir -p /tmp/go \
    && curl -fsSL https://golang.org/dl/go"${GOLANG_VERSION}".linux-"${TARGETARCH}".tar.gz -o /tmp/go.tgz \
    && go_sha="${go_sha=GOLANG_SHA256_${TARGETARCH}}" \
    && echo "${!go_sha} /tmp/go.tgz" | sha256sum -c - \
    && tar -C /usr/local -xzf /tmp/go.tgz \
    && rm /tmp/go.tgz \
    && [[ $(go version) =~ ${GOLANG_VERSION} ]]

FROM base as pulumi
ARG TARGETARCH
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
COPY --from=golang /usr/local/go /usr/local/go
ENV PATH=/usr/local/go/bin:${PATH}
ARG PULUMI_VERSION=3.83.0
RUN curl -fsSL https://get.pulumi.com \
    | sh -s -- --version "${PULUMI_VERSION}" \
    && export PATH="$HOME/.pulumi/bin:$PATH" \
    && pulumi version

FROM base as bicep
ARG TARGETARCH
ARG BICEP_VERSION=v0.21.1
RUN export targetarch="${TARGETARCH}" \
    && if [ "${targetarch}" = "amd64" ]; then export targetarch="x64"; fi \
    && curl -sSLo bicep "https://github.com/Azure/bicep/releases/download/${BICEP_VERSION}/bicep-linux-${targetarch}" \
    && chmod +x ./bicep \
    && mv ./bicep /usr/local/bin/bicep \
    && bicep --version

FROM base as act-base

# automatic buildx ARGs
ARG TARGETARCH

# enable pipefail and set workdir
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
WORKDIR /tmp

# setup environment
ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache \
    AZURE_EXTENSION_DIR=/opt/az/azcliextensions
RUN apt-get -y update \
    && apt-get -y install --no-install-recommends \
        lsb-release \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/* \
    && distro=$(lsb_release --id --short) \
    && version=$(lsb_release --release --short) \
    && locale | tee -a /etc/environment \
    && sed 's|"||g' -i "/etc/environment" \
    && echo "IMAGE_OS=${distro}${version::2}" | tee -a /etc/environment \
    && echo "ImageOS=${distro}${version::2}" | tee -a /etc/environment \
    && echo "LSB_RELEASE=${version}" | tee -a /etc/environment \
    && echo "AGENT_TOOLSDIRECTORY=${AGENT_TOOLSDIRECTORY}" | tee -a /etc/environment \
    && echo "AZURE_EXTENSION_DIR=${AZURE_EXTENSION_DIR}" | tee -a /etc/environment \
    && echo "RUN_TOOL_CACHE=${AGENT_TOOLSDIRECTORY}" | tee -a /etc/environment \
    && echo "DEPLOYMENT_BASEPATH=/opt/runner" | tee -a /etc/environment \
    && echo "LSB_OS_VERSION=${version//./}" | tee -a /etc/environment \
    && echo "USER=$(whoami)" | tee -a /etc/environment \
    && echo "RUNNER_USER=$(whoami)" | tee -a /etc/environment \
    && echo "RUNNER_MANUALLY_TRAP_SIG=${RUNNER_MANUALLY_TRAP_SIG}" | tee -a /etc/environment \
    && echo "ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=${ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT}" | tee -a /etc/environment

# add ssh keys of github and azure devops
# hadolint ignore=SC2174
RUN ssh-keyscan github.com >>/etc/ssh/ssh_known_hosts \
    && ssh-keyscan ssh.dev.azure.com >>/etc/ssh/ssh_known_hosts

# Install dependencies
ARG DEPENDENCIES
RUN apt-get -y update &>/dev/null \
    && apt-get -y install --no-install-recommends jq \
    && packages=() \
    && while IFS='' read -r pkg; do packages+=("$pkg"); done < <(printf "%s\n" "${DEPENDENCIES}" | jq -r '.[]') \
    && apt-get -y install --no-install-recommends \
        "${packages[@]}" \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# Install apt-fast
RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/ilikenwf/apt-fast/master/quick-install.sh)" \
    && apt-get -y upgrade \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# Install current version of git
# hadolint ignore=SC2035
RUN add-apt-repository -y ppa:git-core/ppa \
    && apt-get -y update &>/dev/null \
    && apt-get -y install --no-install-recommends \
        git \
    && printf "[safe]\n\tdirectory = *\n" | tee -a /etc/gitconfig \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# Install Git-LFS
RUN curl -sSL https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash \
    && apt-get -y install --no-install-recommends \
        git-lfs \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# Install docker cli
RUN echo "deb https://packages.microsoft.com/ubuntu/$(lsb_release -rs)/prod $(lsb_release -cs) main" \
    | tee /etc/apt/sources.list.d/microsoft-prod.list \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmour -o /etc/apt/trusted.gpg.d/microsoft.gpg \
    && apt-get -y update &>/dev/null \
    && apt-get -y install --no-install-recommends \
        moby-cli \
        moby-buildx \
        moby-compose \
    && docker -v \
    && docker buildx version \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# Set .NET related environment variables
ARG DOTNET_SDK_VERSION=latest
ARG DOTNET_CHANNEL=STS
ARG DOTNET_DEPS
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_GENERATE_ASPNET_CERTIFICATE=false \
    DOTNET_HOST_PATH=${AGENT_TOOLSDIRECTORY}/dotnet/dotnet \
    DOTNET_MULTILEVEL_LOOKUP=0 \
    DOTNET_NOLOGO=true \
    DOTNET_ROLL_FORWARD=Major \
    DOTNET_ROOT=${AGENT_TOOLSDIRECTORY}/dotnet \
    DOTNET_SDK_VERSION=${DOTNET_SDK_VERSION} \
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    NUGET_XMLDOC_MODE=skip \
    NUGET_PACKAGES=${AGENT_TOOLSDIRECTORY}/nugetpackages \
    PATH=${AGENT_TOOLSDIRECTORY}/dotnet/tools:${AGENT_TOOLSDIRECTORY}/dotnet:${PATH}

# install .NET SDK
RUN printf "Package: *net*\nPin: origin packages.microsoft.com\nPin-Priority: 1001\n" >/etc/apt/preferences.d/dotnet \
    && deps=("libc6" "libgcc1" "libgssapi-krb5-2" "libstdc++6" "zlib1g") \
    && while IFS='' read -r dep; do deps+=("$dep"); done < <(printf "%s\n" "${DOTNET_DEPS}" | jq -r '.[]') \
    && apt-get -y update &>/dev/null \
    && apt-get -y install --no-install-recommends \
        "${deps[@]}" \
    && curl -fsSL https://dot.net/v1/dotnet-install.sh | bash -s -- \
        --install-dir "${DOTNET_ROOT}" \
        --no-path \
        --channel "${DOTNET_CHANNEL}" \
        --version "${DOTNET_SDK_VERSION}" \
    && rm -rf /etc/apt/preferences.d/dotnet \
    && sed "s|^PATH=|PATH=${DOTNET_ROOT}:|mg" -i /etc/environment \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# Install Github CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=${TARGETARCH} signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list >/dev/null \
    && apt-get -y update &>/dev/null \
    && apt-get -y install --no-install-recommends \
        gh \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN [[ $(curl -sL https://packages.microsoft.com/repos/azure-cli/dists/) =~ $(lsb_release -cs) ]] \
    && (export targetarch=${TARGETARCH} \
        && if [ ${targetarch} = "amd64" ]; then export targetarch="x64"; fi \
        && echo "deb [arch=$(dpkg --print-architecture)] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
        | tee /etc/apt/sources.list.d/azure.list \
        && apt-get -y update &>/dev/null \
        && apt-get -y install --no-install-recommends \
            azure-cli \
        && az extension add -n azure-devops \
        && az bicep install --target-platform "linux-${targetarch}" \
        && az config set bicep.use_binary_from_path=true \
        && az config set auto-upgrade.enable=no \
        && az config set auto-upgrade.prompt=no \
        && az config set core.collect_telemetry=false \
        && apt-get clean \
        && rm -rf /etc/apt/sources.list.d/* \
        && rm -rf /var/lib/apt/lists/*) \
    || echo "Azure CLI not available for this distribution"

# Install default NodeJS
ARG NODE_VERSION=20
RUN curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n -o ~/n \
    && bash ~/n "${NODE_VERSION}" \
    && rm -rf ~/n \
    && chmod -R 777 /usr/local/lib/node_modules \
    && chmod -R 777 /usr/local/bin \
    && npm --version

# Install YARN
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg \
    | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" \
    | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get -y update \
    && apt-get -y install --no-install-recommends \
        yarn \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/* \
    && yarn --version

# install python 3, pip, venv, pipx
ENV PIPX_BIN_DIR=/opt/pipx_bin \
    PIPX_HOME=/opt/pipx
ENV PATH=${PIPX_BIN_DIR}:${PATH}
# kics-scan ignore-block
RUN apt-get -y update &>/dev/null \
    && apt-get -y install --no-install-recommends \
        python3 \
        python3-dev \
        python3-pip \
        python3-venv \
    && python3 -m pip install --no-cache-dir \
        pipx \
    && if ! command -v pipx; then echo "pipx was not installed or not found on PATH" && exit 1; fi \
    && sed "s|^PATH=|PATH=${PIPX_BIN_DIR}:|mg" -i /etc/environment \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# cleanup step
RUN apt-get -y clean \
    && rm -rf \
        /var/cache/* \
        /var/log/* \
        /var/lib/apt/lists/* \
        /etc/apt/sources.list.d/* \
        /tmp/* \
    || echo 'Failed to delete directories'

# kics-scan ignore-line
FROM act-base as act-powershell
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
# Install PowerShell global tool
ARG TARGETARCH
ARG POWERSHELL_VERSION=7.2.13
ARG TOOL_PATH_PWSH=/usr/share/powershell
RUN dotnet tool install \
    --tool-path "${TOOL_PATH_PWSH}" \
    --version "${POWERSHELL_VERSION}" \
    PowerShell \
    && find "${TOOL_PATH_PWSH}" -print | grep -i '.*[.]nupkg$' | xargs rm \
    && ln -s "$(realpath --relative-to=/usr/local/bin "${TOOL_PATH_PWSH}")/pwsh" /usr/local/bin/pwsh \
    && chmod 755 "${TOOL_PATH_PWSH}/pwsh" \
    && [[ "$(pwsh --version)" =~ ${POWERSHELL_VERSION} ]]
#     && pwsh -NonInteractive -Command "Install-PackageProvider -Name NuGet -MinimumVersion '2.8.5.201' -Force -Scope AllUsers" \

# kics-scan ignore-line
FROM act-powershell as act-powershell-modules
ARG TARGETARCH
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
ARG POWERSHELL_MODULES
# Trust PSGallery and install Powershell-/Azure Modules
RUN pwsh -NonInteractive -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted" \
    && while IFS='' read -r pwshModule; do echo "installing ${pwshModule}" \
        && pwsh -NonInteractive -Command "Install-Module -Name ${pwshModule} -Scope AllUsers -Repository PSGallery"; done \
        < <(printf "%s\n" "${POWERSHELL_MODULES}" | jq -r '.[]')

# kics-scan ignore-line
FROM act-powershell as act-powershell-az-modules
ARG TARGETARCH
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
ARG POWERSHELL_AZ_MODULE_VERSIONS
# Trust PSGallery and install Powershell-/Azure Modules
RUN pwsh -NonInteractive -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted" \
    && while IFS='' read -r azVersion; do echo "installing Az ${azVersion}" \
        && pwsh -NonInteractive -Command "Install-Module -Name Az -RequiredVersion ${azVersion} -Scope AllUsers -Repository PSGallery"; done \
        < <(printf "%s\n" "${POWERSHELL_AZ_MODULE_VERSIONS}" | jq -r '.[]')

# kics-scan ignore-line
FROM act-base as act
ARG TARGETARCH
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
WORKDIR /tmp

# add go
COPY --from=golang /usr/local/go /usr/local/go
ENV PATH=/usr/local/go/bin:${PATH}
RUN sed "s|^PATH=|PATH=/usr/local/go/bin:|mg" -i /etc/environment

# add pulumi
COPY --from=pulumi /root/.pulumi/bin /usr/local/bin/

# add bicep
COPY --from=bicep /usr/local/bin/bicep /usr/local/bin/bicep

# add PowerShell
ARG TOOL_PATH_PWSH=/usr/share/powershell
COPY --from=act-powershell ${TOOL_PATH_PWSH} ${TOOL_PATH_PWSH}
RUN ln -s "$(realpath --relative-to=/usr/local/bin "${TOOL_PATH_PWSH}")/pwsh" /usr/local/bin/pwsh

# add  PowerShell-modules
COPY --from=act-powershell-modules /usr/local/share/powershell /usr/local/share/powershell
COPY --from=act-powershell-az-modules /usr/local/share/powershell /usr/local/share/powershell

ARG RUNNER
USER ${RUNNER}

# No idea how to do a healthcheck for this image
HEALTHCHECK NONE
