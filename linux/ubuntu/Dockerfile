# syntax=docker/dockerfile:1

ARG FROM_IMAGE=buildpack-deps
ARG FROM_VERSION_MAJOR=22
ARG FROM_VERSION_MINOR=04
ARG FROM_VERSION=${FROM_VERSION_MAJOR}.${FROM_VERSION_MINOR}
FROM --platform=$TARGETPLATFORM ${FROM_IMAGE}:${FROM_VERSION} AS base

# > automatic buildx ARGs
ARG TARGETARCH

# > ARGs before FROM are not accessible
ARG FROM_IMAGE
ARG FROM_VERSION_MAJOR
ARG FROM_VERSION_MINOR
ARG FROM_VERSION=${FROM_VERSION_MAJOR}.${FROM_VERSION_MINOR}

# > Our custom ARGs
# latest Node.js LTS versions
ARG NODE_VERSION="16 18"
ARG DISTRO=ubuntu
ARG CODENAME
ARG TYPE=act

# > Force apt to not be interactive/not ask
ENV DEBIAN_FRONTEND=noninteractive

SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
WORKDIR /tmp

# create targetproc file for later use
RUN export targetarch=${TARGETARCH} \
    && if [ ${targetarch} = "amd64" ]; then export targetarch="x64"; fi \
    && echo ${targetarch} >/tmp/targetproc

# setup environment
ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
RUN sed 's|"||g' -i "/etc/environment" \
    && echo "IMAGE_OS=${DISTRO}${FROM_VERSION_MAJOR}" | tee -a "/etc/environment" \
    && echo "ImageOS=${DISTRO}${FROM_VERSION_MAJOR}" | tee -a "/etc/environment" \
    && echo "LSB_RELEASE=${FROM_VERSION}" | tee -a "/etc/environment" \
    && echo "AGENT_TOOLSDIRECTORY=${AGENT_TOOLSDIRECTORY}" | tee -a "/etc/environment" \
    && echo "RUN_TOOL_CACHE=${AGENT_TOOLSDIRECTORY}" | tee -a "/etc/environment" \
    && echo "DEPLOYMENT_BASEPATH=/opt/runner" | tee -a "/etc/environment" \
    && echo "LSB_OS_VERSION=${FROM_VERSION_MAJOR}${FROM_VERSION_MINOR}" | tee -a "/etc/environment" \
    && echo "USER=$(whoami)" | tee -a "/etc/environment" \
    && echo "RUNNER_USER=$(whoami)" | tee -a "/etc/environment"

# add ssh keys of github and azure devops
# hadolint ignore=SC2174
RUN mkdir -m 0700 -p ~/.ssh \
    && ssh-keyscan -t rsa github.com >>/etc/ssh/ssh_known_hosts \
    && ssh-keyscan -t rsa ssh.dev.azure.com >>/etc/ssh/ssh_known_hosts

# Install Git-LFS
RUN curl -Ls https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash \
    && apt-get -yq install --no-install-recommends --no-install-suggests git-lfs \
    && rm -rf /var/lib/apt/lists/*

# Install dependencies
RUN apt-get -yq update \
    && packages=("ssh" "gawk" "curl" "jq" "wget" "sudo" "gnupg-agent" "ca-certificates" "software-properties-common" "apt-transport-https" "libyaml-0-2" "zstd" "zip" "unzip" "xz-utils") \
    && apt-get -yq install \
        --no-install-recommends \
        --no-install-suggests \
        "${packages[@]}" \
    && rm -rf /var/lib/apt/lists/*

# install apt packages from toolset
COPY linux/${DISTRO}/toolsets/${FROM_VERSION_MAJOR}${FROM_VERSION_MINOR}.json /imagegeneration/toolset.json
# hadolint ignore=SC2207
RUN apt-get -yq update \
    && packages=() && packages+=($(jq -r '.apt|.vital_packages[],.common_packages[],.cmd_packages[]' </imagegeneration/toolset.json)) \
    && apt-get -yq install --no-install-recommends --no-upgrade "${packages[@]}" \
    && ln -s "$(which python3)" "/usr/local/bin/python" \
    && rm -rf /var/lib/apt/lists/*

# Install docker cli
RUN echo "deb https://packages.microsoft.com/ubuntu/$(lsb_release -rs)/prod $(lsb_release -cs) main" \
    | tee /etc/apt/sources.list.d/microsoft-prod.list \
    && curl -sL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor >/etc/apt/trusted.gpg.d/microsoft.gpg \
    && apt-get -yq update \
    && apt-get -yq install --no-install-recommends --no-install-suggests \
        moby-cli \
        moby-buildx \
        moby-compose \
    && docker -v \
    && docker buildx version \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and toolset packages
# hadolint ignore=SC2174,DL3016
RUN <<EOF
IFS=' ' read -r -a NODE <<<"$NODE_VERSION"
for ver in "${NODE[@]}"; do
    printf "\n\t🐋 Installing Node.JS=%s 🐋\t\n" "${ver}"
    VER=$(curl https://nodejs.org/download/release/index.json | jq "[.[] | select(.version|test(\"^v${ver}\"))][0].version" -r)
    NODEPATH="$AGENT_TOOLSDIRECTORY/node/${VER:1}/$(cat /tmp/targetproc)"
    mkdir -v -m 0777 -p "$NODEPATH"
    curl -Ls "https://nodejs.org/download/release/latest-v${ver}.x/node-$VER-linux-$(cat /tmp/targetproc).tar.xz" -o "node-$VER-linux-$(cat /tmp/targetproc).tar.xz"
    tar -Jxf "node-$VER-linux-$(cat /tmp/targetproc).tar.xz" --strip-components=1 -C "$NODEPATH"
    rm "node-$VER-linux-$(cat /tmp/targetproc).tar.xz"
    if [[ "${ver}" == "18" ]]; then  # make this version the default (latest LTS)
        sed "s|^PATH=|PATH=$NODEPATH/bin:|mg" -i /etc/environment
        ln -s "$NODEPATH/bin/node" /usr/local/bin/node
    fi
    export PATH="$NODEPATH/bin:$PATH"
done
# install packages from toolset
packages=()
while IFS='' read -r line; do packages+=("$line"); done < <(jq -r '.node_modules[].name' /imagegeneration/toolset.json)
npm update -g npm
npm install -g "${packages[@]}"
chmod -R 777 /usr/local/lib/node_modules
chmod -R 777 /usr/local/bin
npm cache clean --force
EOF

# Set .NET related environment variables
ENV DOTNET_ROOT=${AGENT_TOOLSDIRECTORY}/dotnet
ENV PATH=${DOTNET_ROOT}:${PATH}
ENV DOTNET_GENERATE_ASPNET_CERTIFICATE=false
ENV DOTNET_NOLOGO=true
ENV DOTNET_SDK_VERSION=6.0.413
ENV DOTNET_USE_POLLING_FILE_WATCHER=true
ENV NUGET_XMLDOC_MODE=skip

# install .NET SDK LTS
RUN export fromVersion=${FROM_VERSION} \
    && deps=("libc6" "libgcc1" "libgssapi-krb5-2" "libstdc++6" "zlib1g") \
    && if [ "${fromVersion}" = "20.04" ]; then deps+=("libicu66" "libssl1.1"); fi \
    && if [ "${fromVersion}" = "22.04" ]; then deps+=("libicu70" "libssl3" "libunwind8"); fi \
    && apt-get -yq update && apt-get -yq install --no-install-recommends --no-upgrade "${deps[@]}" \
    && curl -L https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh \
    && chmod +x ./dotnet-install.sh \
    && ./dotnet-install.sh \
        --install-dir "${DOTNET_ROOT}" \
        --no-path \
        --channel LTS \
        --version "${DOTNET_SDK_VERSION}" \
    && rm -rf ./dotnet-install.sh \
    && dotnet --info \
    && sed "s|^PATH=|PATH=$DOTNET_ROOT:|mg" -i /etc/environment \
    && rm -rf /var/lib/apt/lists/*

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

# # Trust PSGallery and install Azure Powershell Modules
RUN export azVersion=10.2.0 \
    && pwsh -NonInteractive -NoProfile \
        -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted" \
    && pwsh -NonInteractive -NoProfile \
        -Command "Install-Module -Name Az -RequiredVersion ${azVersion} -Scope AllUsers -Repository PSGallery"

# Install Github CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$TARGETARCH signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list >/dev/null \
    && apt-get -yq update \
    && apt-get -yq install --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN [[ $(curl -sL https://packages.microsoft.com/repos/azure-cli/dists/) =~ $(lsb_release -cs) ]] \
    && (curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >/etc/apt/trusted.gpg.d/microsoft.gpg \
        && echo "deb [arch=$(dpkg --print-architecture)] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
            >/etc/apt/sources.list.d/azure-cli.list \
        && apt-get -yq update \
        && apt-get -yq install --no-install-recommends azure-cli \
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

# cleanup step
RUN apt-get -yq clean \
    && rm -rf \
        /var/cache/* \
        /var/log/* \
        /var/lib/apt/lists/* \
        /tmp/* \
    || echo 'Failed to delete directories'

ARG RUNNER
USER ${RUNNER}

# add environment variables to bashrc
RUN echo ". /etc/environment" | tee -a /etc/bash.bashrc -a ~/.bashrc
