# syntax=docker/dockerfile:1
# kics-scan disable=e36d8880-3f78-4546-b9a1-12f0745ca0d5,965a08d7-ef86-4f14-8792-4a3b2098937e,77783205-c4ca-4f80-bb80-c777f267c547
ARG FROM_IMAGE=buildpack-deps
ARG FROM_VERSION_MAJOR=22
ARG FROM_VERSION_MINOR=04
ARG FROM_VERSION=${FROM_VERSION_MAJOR}.${FROM_VERSION_MINOR}
FROM ${FROM_IMAGE}:${FROM_VERSION}

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

# set locale
ENV LANG=C.UTF-8

SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
WORKDIR /tmp

# create targetproc file for later use
RUN export targetarch=${TARGETARCH} \
    && if [ ${targetarch} = "amd64" ]; then export targetarch="x64"; fi \
    && echo ${targetarch} >/tmp/targetproc

# setup environment
ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
RUN sed 's|"||g' -i "/etc/environment" \
    && echo "IMAGE_OS=${DISTRO}${FROM_VERSION_MAJOR}" | tee -a /etc/environment \
    && echo "ImageOS=${DISTRO}${FROM_VERSION_MAJOR}" | tee -a /etc/environment \
    && echo "LSB_RELEASE=${FROM_VERSION}" | tee -a /etc/environment \
    && echo "AGENT_TOOLSDIRECTORY=${AGENT_TOOLSDIRECTORY}" | tee -a /etc/environment \
    && echo "RUN_TOOL_CACHE=${AGENT_TOOLSDIRECTORY}" | tee -a /etc/environment \
    && echo "DEPLOYMENT_BASEPATH=/opt/runner" | tee -a /etc/environment \
    && echo "LSB_OS_VERSION=${FROM_VERSION_MAJOR}${FROM_VERSION_MINOR}" | tee -a /etc/environment \
    && echo "USER=$(whoami)" | tee -a /etc/environment \
    && echo "RUNNER_USER=$(whoami)" | tee -a /etc/environment

# add ssh keys of github and azure devops
# hadolint ignore=SC2174
RUN ssh-keyscan github.com >>/etc/ssh/ssh_known_hosts \
    && ssh-keyscan ssh.dev.azure.com >>/etc/ssh/ssh_known_hosts

# Install current version of git
RUN add-apt-repository -y ppa:git-core/ppa \
    && apt-get -y update \
    && apt-get -y install --no-install-recommends git \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# Install dependencies
RUN apt-get -y update \
    && packages=(gawk sudo jq gnupg-agent ca-certificates software-properties-common apt-transport-https zstd zip unzip xz-utils) \
    && apt-get -y install --no-install-recommends --no-install-suggests \
        "${packages[@]}" \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# Install apt-fast
RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/ilikenwf/apt-fast/master/quick-install.sh)" \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# Install Git-LFS
RUN curl -Ls https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash \
    && apt-get -y install --no-install-recommends --no-install-suggests \
        git-lfs \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# Install docker cli
RUN echo "deb https://packages.microsoft.com/ubuntu/$(lsb_release -rs)/prod $(lsb_release -cs) main" \
    | tee /etc/apt/sources.list.d/microsoft-prod.list \
    && curl -sL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor >/etc/apt/trusted.gpg.d/microsoft.gpg \
    && apt-get -y update \
    && apt-get -y install --no-install-recommends --no-install-suggests \
        moby-cli \
        moby-buildx \
        moby-compose \
    && docker -v \
    && docker buildx version \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# Set .NET related environment variables
ENV \
    DOTNET_ROOT=${AGENT_TOOLSDIRECTORY}/dotnet \
    PATH=${AGENT_TOOLSDIRECTORY}/dotnet:${PATH} \
    DOTNET_GENERATE_ASPNET_CERTIFICATE=false \
    DOTNET_NOLOGO=true \
    DOTNET_SDK_VERSION=6.0.413 \
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    NUGET_XMLDOC_MODE=skip \
    DOTNET_CLI_TELEMETRY_OPTOUT=1

# install .NET SDK LTS
RUN export fromVersion=${FROM_VERSION} \
    && deps=("libc6" "libgcc1" "libgssapi-krb5-2" "libstdc++6" "zlib1g") \
    && if [ "${fromVersion}" = "20.04" ]; then deps+=("libicu66" "libssl1.1"); fi \
    && if [ "${fromVersion}" = "22.04" ]; then deps+=("libicu70" "libssl3" "libunwind8"); fi \
    && apt-get -y update \
    && apt-get -y install --no-install-recommends \
        "${deps[@]}" \
    && curl -L https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh \
    && chmod +x ./dotnet-install.sh \
    && ./dotnet-install.sh \
        --install-dir "${DOTNET_ROOT}" \
        --no-path \
        --channel LTS \
        --version "${DOTNET_SDK_VERSION}" \
    && rm -rf ./dotnet-install.sh \
    && dotnet --info \
    && sed "s|^PATH=|PATH=${DOTNET_ROOT}:|mg" -i /etc/environment \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# Install PowerShell global tool
RUN export powershell_version=7.2.13 \
    && export tool_path=/usr/share/powershell \
    && curl -fSL \
        --output PowerShell.Linux."$(cat /tmp/targetproc)".${powershell_version}.nupkg \
        https://pwshtool.blob.core.windows.net/tool/${powershell_version}/PowerShell.Linux."$(cat /tmp/targetproc)".${powershell_version}.nupkg \
    && dotnet tool install \
        --add-source / \
        --tool-path "${tool_path}" \
        --version ${powershell_version} \
        PowerShell.Linux."$(cat /tmp/targetproc)" \
    && dotnet nuget locals all --clear \
    && rm PowerShell.Linux."$(cat /tmp/targetproc)".${powershell_version}.nupkg \
    && ln -s "${tool_path}/pwsh" /usr/bin/pwsh \
    && chmod 755 "${tool_path}/pwsh" \
    && find "${tool_path}" -print | grep -i '.*[.]nupkg$' | xargs rm

# Install Github CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=${TARGETARCH} signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list >/dev/null \
    && apt-get -y update \
    && apt-get -y install --no-install-recommends \
        gh \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN [[ $(curl -sL https://packages.microsoft.com/repos/azure-cli/dists/) =~ $(lsb_release -cs) ]] \
    && (curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >/etc/apt/trusted.gpg.d/microsoft.gpg \
        && echo "deb [arch=$(dpkg --print-architecture)] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
            >/etc/apt/sources.list.d/azure-cli.list \
        && apt-get -y update \
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
RUN curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-"$(cat /tmp/targetproc)" \
    && chmod +x ./bicep \
    && mv ./bicep /usr/local/bin/bicep

# Add toolset.json
ARG TOOLSET=/imagegeneration/toolset.json
COPY linux/${DISTRO}/toolsets/${FROM_VERSION_MAJOR}${FROM_VERSION_MINOR}.json ${TOOLSET}

# install apt packages from toolset
# hadolint ignore=SC2207
RUN apt-get -y update \
    && packages=() \
    && while IFS='' read -r line; do packages+=("${line}"); done < <(jq -r '.apt|.vital_packages[],.common_packages[],.cmd_packages[]' ${TOOLSET}) \
    && apt-get -y install --no-install-recommends --no-upgrade \
        "${packages[@]}" \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# Install default NodeJS and toolset node_modules
# hadolint ignore=SC2174
RUN curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n -o ~/n \
    && defaultVersion=$(jq -r '.node.default' ${TOOLSET}) \
    && bash ~/n "${defaultVersion}" \
    && while IFS='' read -r node_module; do echo "installing ${node_module}" && npm install -g "${node_module}"; done < <(jq -r '.node_modules[].name' ${TOOLSET}) \
    && echo "Creating the symlink for [now] command to vercel CLI" && ln -s /usr/local/bin/vercel /usr/local/bin/now \
    && chmod -R 777 /usr/local/lib/node_modules \
    && chmod -R 777 /usr/local/bin \
    && rm -rf ~/n

# Trust PSGallery and install Powershell-/Azure Modules
RUN pwsh -NonInteractive -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted" \
    && while IFS='' read -r pwshModule; do echo "installing ${pwshModule}" && pwsh -NonInteractive -Command "Install-Module -Name ${pwshModule} -Scope AllUsers -Repository PSGallery"; done < <(jq -r '.powershellModules[].name' ${TOOLSET}) \
    && while IFS='' read -r azVersion; do echo "installing Az ${azVersion}" && pwsh -NonInteractive -Command "Install-Module -Name Az -RequiredVersion ${azVersion} -Scope AllUsers -Repository PSGallery"; done < <(jq -r '.azureModules[].versions[]' ${TOOLSET})

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
