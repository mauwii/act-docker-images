# syntax=docker/dockerfile:1
# kics-scan disable=e36d8880-3f78-4546-b9a1-12f0745ca0d5,965a08d7-ef86-4f14-8792-4a3b2098937e,77783205-c4ca-4f80-bb80-c777f267c547
ARG FROM_IMAGE=buildpack-deps
ARG FROM_VERSION_MAJOR=22
ARG FROM_VERSION_MINOR=04
ARG FROM_VERSION=${FROM_VERSION_MAJOR}.${FROM_VERSION_MINOR}
ARG BUILDKIT_SBOM_SCAN_CONTEXT=true
FROM ${FROM_IMAGE}:${FROM_VERSION}
ARG BUILDKIT_SBOM_SCAN_STAGE=true

# automatic buildx ARGs
ARG TARGETARCH

# ARGs used before `FROM` are not accessible afterwards
ARG FROM_IMAGE
ARG FROM_VERSION_MAJOR
ARG FROM_VERSION_MINOR
ARG FROM_VERSION=${FROM_VERSION_MAJOR}.${FROM_VERSION_MINOR}

# Our custom ARGs
ARG DISTRO=ubuntu
ARG CODENAME
ARG TYPE=act

# Force apt to not be interactive/not ask
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt to always assume Y
RUN echo "APT::Get::Assume-Yes \"true\";" >/etc/apt/apt.conf.d/90assumeyes

# set locale
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        locales \
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    RUNNER_MANUALLY_TRAP_SIG=1 \
    ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1

# enable pipefail and set workdir
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
WORKDIR /tmp

# create targetproc file for later use
RUN export targetarch=${TARGETARCH} \
    && if [ ${targetarch} = "amd64" ]; then export targetarch="x64"; fi \
    && echo ${targetarch} >/tmp/targetproc

# setup environment
ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache \
    AZURE_EXTENSION_DIR=/opt/az/azcliextensions
RUN locale | tee -a /etc/environment \
    && sed 's|"||g' -i "/etc/environment" \
    && echo "IMAGE_OS=${DISTRO}${FROM_VERSION_MAJOR}" | tee -a /etc/environment \
    && echo "ImageOS=${DISTRO}${FROM_VERSION_MAJOR}" | tee -a /etc/environment \
    && echo "LSB_RELEASE=${FROM_VERSION}" | tee -a /etc/environment \
    && echo "AGENT_TOOLSDIRECTORY=${AGENT_TOOLSDIRECTORY}" | tee -a /etc/environment \
    && echo "AZURE_EXTENSION_DIR=$AZURE_EXTENSION_DIR" | tee -a /etc/environment \
    && echo "RUN_TOOL_CACHE=${AGENT_TOOLSDIRECTORY}" | tee -a /etc/environment \
    && echo "DEPLOYMENT_BASEPATH=/opt/runner" | tee -a /etc/environment \
    && echo "LSB_OS_VERSION=${FROM_VERSION_MAJOR}${FROM_VERSION_MINOR}" | tee -a /etc/environment \
    && echo "USER=$(whoami)" | tee -a /etc/environment \
    && echo "RUNNER_USER=$(whoami)" | tee -a /etc/environment \
    && echo "RUNNER_MANUALLY_TRAP_SIG=${RUNNER_MANUALLY_TRAP_SIG}" | tee -a /etc/environment \
    && echo "ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=${ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT}" | tee -a /etc/environment

# add ssh keys of github and azure devops
# hadolint ignore=SC2174
RUN ssh-keyscan github.com >>/etc/ssh/ssh_known_hosts \
    && ssh-keyscan ssh.dev.azure.com >>/etc/ssh/ssh_known_hosts

# Install dependencies
RUN apt-get -y update &>/dev/null \
    && packages=(gawk sudo jq gnupg-agent ca-certificates software-properties-common apt-transport-https zstd zip unzip xz-utils) \
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
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_GENERATE_ASPNET_CERTIFICATE=false \
    DOTNET_HOST_PATH=${AGENT_TOOLSDIRECTORY}/dotnet/dotnet \
    DOTNET_MULTILEVEL_LOOKUP=0 \
    DOTNET_NOLOGO=true \
    DOTNET_ROLL_FORWARD=Major \
    DOTNET_ROOT=${AGENT_TOOLSDIRECTORY}/dotnet \
    DOTNET_SDK_VERSION=6.0.414 \
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    NUGET_XMLDOC_MODE=skip \
    NUGET_PACKAGES=${AGENT_TOOLSDIRECTORY}/nugetpackages \
    PATH=${AGENT_TOOLSDIRECTORY}/dotnet/tools:${AGENT_TOOLSDIRECTORY}/dotnet:${PATH}

# install .NET SDK LTS
RUN printf "Package: *net*\nPin: origin packages.microsoft.com\nPin-Priority: 1001\n" >/etc/apt/preferences.d/dotnet \
    && deps=("libc6" "libgcc1" "libgssapi-krb5-2" "libstdc++6" "zlib1g") \
    && if [ "${FROM_VERSION}" = "20.04" ]; then deps+=("libicu66" "libssl1.1"); fi \
    && if [ "${FROM_VERSION}" = "22.04" ]; then deps+=("libicu70" "libssl3" "libunwind8"); fi \
    && apt-get -y update &>/dev/null \
    && apt-get -y install --no-install-recommends \
        "${deps[@]}" \
    && curl -fsSL https://dot.net/v1/dotnet-install.sh | bash -s -- \
        --install-dir "${DOTNET_ROOT}" \
        --no-path \
        --channel LTS \
        --version "${DOTNET_SDK_VERSION}" \
    && rm -rf /etc/apt/preferences.d/dotnet \
    && sed "s|^PATH=|PATH=${DOTNET_ROOT}:|mg" -i /etc/environment \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# Install PowerShell global tool
RUN export powershell_version=7.2.13 \
    && export tool_path=/usr/share/powershell \
    && pwsh_nupkg="PowerShell.Linux.$(cat /tmp/targetproc).${powershell_version}.nupkg" \
    && export pwsh_nupkg \
    && curl -fsSLO "https://pwshtool.blob.core.windows.net/tool/${powershell_version}/${pwsh_nupkg}" \
    && dotnet tool install \
        --add-source / \
        --tool-path "${tool_path}" \
        --version "${powershell_version}" \
        PowerShell.Linux."$(cat /tmp/targetproc)" \
    && dotnet nuget locals all --clear \
    && rm "${pwsh_nupkg}" \
    && ln -s "${tool_path}/pwsh" /usr/bin/pwsh \
    && chmod 755 "${tool_path}/pwsh" \
    && find "${tool_path}" -print | grep -i '.*[.]nupkg$' | xargs rm

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
    && (echo "deb [arch=$(dpkg --print-architecture)] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
        | tee /etc/apt/sources.list.d/azure.list \
        && apt-get -y update &>/dev/null \
        && apt-get -y install --no-install-recommends \
            azure-cli \
        && az extension add -n azure-devops \
        && az bicep install --target-platform "linux-$(cat /tmp/targetproc)" \
        && az config set bicep.use_binary_from_path=true \
        && az config set auto-upgrade.enable=no \
        && az config set auto-upgrade.prompt=no \
        && az config set core.collect_telemetry=false \
        && apt-get clean \
        && rm -rf /etc/apt/sources.list.d/* \
        && rm -rf /var/lib/apt/lists/*) \
    || echo "Azure CLI not available for this distribution"

# install bicep-cli
RUN curl -sSLo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-"$(cat /tmp/targetproc)" \
    && chmod +x ./bicep \
    && mv ./bicep /usr/local/bin/bicep

# Add toolset.json
ARG TOOLSET=/imagegeneration/toolset.json
COPY linux/${DISTRO}/toolsets/${FROM_VERSION_MAJOR}${FROM_VERSION_MINOR}.json ${TOOLSET}

# install apt packages from toolset
# hadolint ignore=SC2207
RUN apt-get -y update &>/dev/null \
    && packages=() \
    && while IFS='' read -r line; do packages+=("${line}"); done < <(jq -r '.apt|.vital_packages[],.common_packages[],.cmd_packages[]' ${TOOLSET}) \
    && apt-get -y install --no-install-recommends \
        "${packages[@]}" \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# Install default NodeJS and toolset node_modules
RUN curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n -o ~/n \
    && defaultVersion=$(jq -r '.node.default' ${TOOLSET}) \
    && bash ~/n "${defaultVersion}" \
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

# Trust PSGallery and install Powershell-/Azure Modules
RUN pwsh -NonInteractive -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted" \
    && while IFS='' read -r pwshModule; do echo "installing ${pwshModule}" && pwsh -NonInteractive -Command "Install-Module -Name ${pwshModule} -Scope AllUsers -Repository PSGallery"; done < <(jq -r '.powershellModules[].name' ${TOOLSET}) \
    && while IFS='' read -r azVersion; do echo "installing Az ${azVersion}" && pwsh -NonInteractive -Command "Install-Module -Name Az -RequiredVersion ${azVersion} -Scope AllUsers -Repository PSGallery"; done < <(jq -r '.azureModules[].versions[]' ${TOOLSET})

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

# Install Go
ENV PATH=/usr/local/go/bin:${PATH}
# hadolint ignore=SC2086
ARG GOLANG_SHA256_amd64=cc97c28d9c252fbf28f91950d830201aa403836cbed702a05932e63f7f0c7bc4
ARG GOLANG_SHA256_arm64=15ab379c6a2b0d086fe3e74be4599420e66549edf7426a300ee0f3809500f89e
ARG GOLANG_VERSION=1.20.8
RUN curl -fsSL https://golang.org/dl/go"${GOLANG_VERSION}".linux-"${TARGETARCH}".tar.gz -o /tmp/go.tgz \
    && go_sha="${go_sha=GOLANG_SHA256_${TARGETARCH}}" \
    && echo "${!go_sha} /tmp/go.tgz" | sha256sum -c - \
    && tar -C /usr/local -xzf /tmp/go.tgz \
    && rm /tmp/go.tgz \
    && go version \
    && sed "s|^PATH=|PATH=/usr/local/go/bin:|mg" -i /etc/environment

# Install latest Pulumi
RUN curl -fsSL https://get.pulumi.com | sh \
    && mv ~/.pulumi/bin/* /usr/local/bin \
    && pulumi version

# cleanup step
RUN apt-get -y clean \
    && rm -rf \
        /var/cache/* \
        /var/log/* \
        /var/lib/apt/lists/* \
        /tmp/* \
    || echo 'Failed to delete directories'

ARG RUNNER
USER ${RUNNER}

# No idea how to do a healthcheck for this image
HEALTHCHECK NONE
