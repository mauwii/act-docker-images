# syntax=docker/dockerfile:1
# kics-scan disable=e36d8880-3f78-4546-b9a1-12f0745ca0d5,965a08d7-ef86-4f14-8792-4a3b2098937e,77783205-c4ca-4f80-bb80-c777f267c547,0008c003-79aa-42d8-95b8-1c2fe37dbfe6,efbf148a-67e9-42d2-ac47-02fa1c0d0b22

##############
# base-image #
##############

ARG FROM_VERSION
FROM buildpack-deps:${FROM_VERSION} as base

ARG TARGETARCH
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]

# Force apt to not be interactive/not ask
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt to always assume Y
RUN echo "APT::Get::Assume-Yes \"true\";" >/etc/apt/apt.conf.d/90assumeyes

# set locale
ARG LANGUAGE=en_US
RUN apt-get -y update >/dev/null \
    && apt-get -y install --no-install-recommends \
        locales \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/* \
    && localedef \
        --inputfile="${LANGUAGE}" \
        --force \
        --charmap=UTF-8 \
        --alias-file=/usr/share/locale/locale.alias "${LANGUAGE}.UTF-8"
ENV LANG=${LANGUAGE}.utf8 \
    LANGUAGE=${LANGUAGE} \
    LC_ALL=${LANGUAGE}.utf8 \
    RUNNER_MANUALLY_TRAP_SIG=1 \
    ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1

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
    && apt-get -y install --no-install-recommends \
        jq \
    && packages=() \
    && while IFS='' read -r pkg; do packages+=("$pkg"); done < <(printf "%s\n" "${DEPENDENCIES}" | jq -r '.[]') \
    && apt-get -y install --no-install-recommends \
        "${packages[@]}" \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# Set .NET related environment variables
ARG DOTNET_SDK_VERSION
ARG DOTNET_CHANNEL
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
    && curl -fsSL https://dot.net/v1/dotnet-install.sh \
    | bash -s -- \
        --install-dir "${DOTNET_ROOT}" \
        --no-path \
        --channel "${DOTNET_CHANNEL}" \
        --version "${DOTNET_SDK_VERSION}" \
    && rm -rf /etc/apt/preferences.d/dotnet \
    && sed "s|^PATH=|PATH=${DOTNET_ROOT}:|mg" -i /etc/environment \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

# Install apt-fast
RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/ilikenwf/apt-fast/master/quick-install.sh)" \
    && apt-get -y upgrade \
    && apt-get clean \
    && rm -rf /etc/apt/sources.list.d/* \
    && rm -rf /var/lib/apt/lists/*

##################
# download tools #
##################

ARG FROM_VERSION
FROM buildpack-deps:${FROM_VERSION} as golang
ARG TARGETARCH
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
ENV PATH=/usr/local/go/bin:${PATH}
ARG GOLANG_SHA256_amd64
ARG GOLANG_SHA256_arm64
ARG GOLANG_VERSION
RUN mkdir -p /tmp/go \
    && curl -fsSL "https://golang.org/dl/go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz" \
        -o /tmp/go.tar.gz \
    && go_sha="${go_sha=GOLANG_SHA256_${TARGETARCH}}" \
    && echo "${!go_sha} /tmp/go.tar.gz" | sha256sum -c - \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz \
    && [[ $(go version) =~ ${GOLANG_VERSION} ]]

ARG FROM_VERSION
FROM buildpack-deps:${FROM_VERSION} as pulumi
ARG TARGETARCH
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
ARG PULUMI_VERSION
RUN curl -fsSL https://get.pulumi.com \
    | sh -s -- \
        --version "${PULUMI_VERSION}" \
    && export PATH="$HOME/.pulumi/bin:$PATH" \
    && pulumi version

ARG FROM_VERSION
FROM buildpack-deps:${FROM_VERSION} as bicep
ARG TARGETARCH
ARG PATH_LOCAL_BINS
ARG BICEP_VERSION=v0.21.1
RUN export targetarch="${TARGETARCH}" \
    && if [ "${targetarch}" = "amd64" ]; then export targetarch="x64"; fi \
    && curl -sSL "https://github.com/Azure/bicep/releases/download/${BICEP_VERSION}/bicep-linux-${targetarch}" \
        -o "${PATH_LOCAL_BINS}/bicep" \
    && chmod +x "${PATH_LOCAL_BINS}/bicep" \
    && bicep --version

ARG FROM_VERSION
FROM buildpack-deps:${FROM_VERSION} as azcopy
ARG TARGETARCH
ARG PATH_LOCAL_BINS
RUN [ "${TARGETARCH:-}" != "" ] || (echo "missing build-arg TARGETARCH" && exit 1) \
    && if [ "${TARGETARCH}" = "arm64" ]; then export azcopy_arch=${TARGETARCH}; fi \
    && curl -sSL "https://aka.ms/downloadazcopy-v10-linux${azcopy_arch:+-$azcopy_arch}" -o /tmp/azcopy.tar.gz \
    && tar -xzf /tmp/azcopy.tar.gz --strip-components=1 -C /tmp \
    && chmod +x /tmp/azcopy \
    && mv /tmp/azcopy "${PATH_LOCAL_BINS}/azcopy"
    # \
    # && azcopy --version

ARG FROM_VERSION
FROM buildpack-deps:${FROM_VERSION} as git-lfs
ARG TARGETARCH
ARG PATH_LOCAL_BINS
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
ARG GIT_LFS_VERSION
ARG GIT_LFS_SHA256_amd64
ARG GIT_LFS_SHA256_arm64
RUN curl -sSL "https://github.com/git-lfs/git-lfs/releases/download/v${GIT_LFS_VERSION}/git-lfs-linux-${TARGETARCH}-v${GIT_LFS_VERSION}.tar.gz" \
    -o /tmp/git-lfs.tar.gz \
    && git_lfs_sha="${git_lfs_sha=GIT_LFS_SHA256_${TARGETARCH}}" \
    && echo "${!git_lfs_sha} /tmp/git-lfs.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/git-lfs.tar.gz --strip-components=1 -C /tmp \
    && chmod +x /tmp/git-lfs \
    && mv /tmp/git-lfs "${PATH_LOCAL_BINS}/git-lfs" \
    && git-lfs --version

ARG FROM_VERSION
FROM buildpack-deps:${FROM_VERSION} as k8s-tools
ARG TARGETARCH
ARG PATH_LOCAL_BINS
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
RUN KUBECTL_VERSION=$(curl -fsSL "https://dl.k8s.io/release/stable.txt") \
    && curl -sSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
        -o "${PATH_LOCAL_BINS}/kubectl" \
    && chmod +x "${PATH_LOCAL_BINS}/kubectl" \
    && curl -sSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash \
    && curl -sSLO "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-${TARGETARCH}" \
    && install "minikube-linux-${TARGETARCH}" "${PATH_LOCAL_BINS}/minikube"

ARG FROM_VERSION
FROM buildpack-deps:${FROM_VERSION} as miniconda
ARG TARGETARCH
ARG PATH_LOCAL_BINS
ARG CONDA_PATH
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
RUN targetarch="$(dpkg-architecture --query DEB_TARGET_GNU_CPU)" && if [[ "${targetarch}" == "amd64" ]]; then targetarch=x86_64; fi \
    && curl -fsSL "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-${targetarch}.sh" \
        -o miniconda.sh \
    && chmod +x miniconda.sh \
    && ./miniconda.sh -b -p ${CONDA_PATH} \
    && rm miniconda.sh

FROM base as pypy
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
ARG PYPY_VERSIONS
RUN export PYPY_VERSIONS_JSON=/tmp/pypy_versions.json \
    && curl -fsSL https://downloads.python.org/pypy/versions.json -o "${PYPY_VERSIONS_JSON}" \
    && arch="$(uname -m)" && if [[ "${arch}" = "x86_64" ]]; then arch="x64"; fi \
    && export arch \
    && export PYPY_TMP_ARCHIVE=/tmp/pypy.tar.bz2 \
    && versions=() \
    && while IFS='' read -r version; do versions+=("$version"); done < <(printf "%s\n" "${PYPY_VERSIONS}" | jq -r '.[]') \
    && for version in "${versions[@]}"; do latest_python_version=$(jq --arg version "$version" -r '.[] | select((.python_version | startswith($version)) and (.stable==true)) | .python_version' "${PYPY_VERSIONS_JSON}" | sort -V | tail -n1) \
        && echo "loading PyPy ${latest_python_version} for arch ${arch}" \
        && curl -fsSL "$(jq \
            --arg latest_python_version "${latest_python_version}" \
            --arg arch "${arch}" \
            -r 'map(select((.python_version==$latest_python_version) and .stable==true) | .files[] | select((.arch==$arch) and (.platform=="linux")) | .download_url) | .[]' "${PYPY_VERSIONS_JSON}")" \
            -o "${PYPY_TMP_ARCHIVE}" \
        && PYPY_TOOLCACHE_DIR="${AGENT_TOOLSDIRECTORY}/PyPy" \
        && PYPY_TOOLCACHE_VERSION_DIR="${PYPY_TOOLCACHE_DIR}/${latest_python_version}" \
        && PYPY_TOOLCACHE_VERSION_ARCH_DIR="${PYPY_TOOLCACHE_VERSION_DIR}/${arch}" \
        && mkdir -p "$PYPY_TOOLCACHE_VERSION_ARCH_DIR" \
        && tar -xjf "${PYPY_TMP_ARCHIVE}" \
            --strip-components=1 \
            -C "$PYPY_TOOLCACHE_VERSION_ARCH_DIR" \
        && printf "%s\n" "$("${PYPY_TOOLCACHE_VERSION_ARCH_DIR}/bin/python" -c "import sys;print('{}.{}.{}'.format(*sys.pypy_version_info[0:3]))")" >"${PYPY_TOOLCACHE_VERSION_ARCH_DIR}/PYPY_VERSION" \
        && touch "${PYPY_TOOLCACHE_VERSION_ARCH_DIR}.complete" \
        && rm "${PYPY_TMP_ARCHIVE}"; done \
    && rm "${PYPY_VERSIONS_JSON}"

FROM base as terraform
ARG TARGETARCH
ARG PATH_LOCAL_BINS
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
RUN URL=$(curl -fsSL https://api.releases.hashicorp.com/v1/releases/terraform/latest \
    | jq --arg arch "$(dpkg --print-architecture)" -r '.builds[] | select((.arch==$arch) and (.os=="linux")).url') \
    && curl -sSL "${URL}" \
        -o /tmp/terraform.zip \
    && unzip \
        -qq /tmp/terraform.zip \
        -d "${PATH_LOCAL_BINS}" \
    && terraform --version

FROM base as packer
ARG TARGETARCH
ARG PATH_LOCAL_BINS
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
RUN URL=$(curl -fsSL https://api.releases.hashicorp.com/v1/releases/packer/latest | jq --arg arch "${TARGETARCH}" -r '.builds[] | select((.arch==$arch) and (.os=="linux")).url') \
    && ZIP_NAME="packer_linux_amd64.zip" \
    && curl -fsSL "${URL}" -o "/tmp/${ZIP_NAME}" \
    && unzip -qq "/tmp/${ZIP_NAME}" -d "${PATH_LOCAL_BINS}" \
    && packer --version \
    && rm -f "/tmp/${ZIP_NAME}"

FROM base as rust
ARG TARGETARCH
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
ARG RUSTUP_HOME
ARG CARGO_HOME
ENV PATH=${CARGO_HOME}/bin:${PATH}
RUN curl -fsSL https://sh.rustup.rs \
    | sh -s -- \
        -y \
        --default-toolchain=stable \
        --profile minimal \
    && cargo --version \
    && rustc --version

FROM base as dotnet-powershell
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
# Install PowerShell global tool
ARG TARGETARCH
ARG PATH_LOCAL_BINS
ARG POWERSHELL_VERSION=7.2.13
ARG TOOL_PATH_PWSH=/usr/share/powershell
RUN dotnet tool install \
    --tool-path "${TOOL_PATH_PWSH}" \
    --version "${POWERSHELL_VERSION}" \
    PowerShell \
    && find "${TOOL_PATH_PWSH}" -print | grep -i '.*[.]nupkg$' | xargs rm \
    && ln -s "$(realpath --relative-to="${PATH_LOCAL_BINS}" "${TOOL_PATH_PWSH}")/pwsh" "${PATH_LOCAL_BINS}/pwsh" \
    && chmod 755 "${TOOL_PATH_PWSH}/pwsh" \
    && [[ "$(pwsh --version)" =~ ${POWERSHELL_VERSION} ]]

FROM base as dotnet-powershell-modules
ARG TARGETARCH
ARG PATH_LOCAL_BINS
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
ARG TOOL_PATH_PWSH=/usr/share/powershell
COPY --link --from=dotnet-powershell "${TOOL_PATH_PWSH}" "${TOOL_PATH_PWSH}"
RUN ln -s "$(realpath --relative-to="${PATH_LOCAL_BINS}" "${TOOL_PATH_PWSH}")/pwsh" "${PATH_LOCAL_BINS}/pwsh"
ARG POWERSHELL_MODULES
RUN pwsh -NonInteractive -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted" \
    && while IFS='' read -r pwshModule; do echo "installing ${pwshModule}" \
        && pwsh -NonInteractive -Command "Install-Module -Name ${pwshModule} -Scope AllUsers -Repository PSGallery"; done \
        < <(printf "%s\n" "${POWERSHELL_MODULES}" | jq -r '.[]')

FROM base as dotnet-powershell-az-modules
ARG TARGETARCH
ARG PATH_LOCAL_BINS
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
ARG TOOL_PATH_PWSH=/usr/share/powershell
COPY --link --from=dotnet-powershell "${TOOL_PATH_PWSH}" "${TOOL_PATH_PWSH}"
RUN ln -s "$(realpath --relative-to="${PATH_LOCAL_BINS}" "${TOOL_PATH_PWSH}")/pwsh" "${PATH_LOCAL_BINS}/pwsh"
ARG POWERSHELL_AZ_MODULE_VERSIONS
RUN pwsh -NonInteractive -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted" \
    && while IFS='' read -r azVersion; do echo "installing Az ${azVersion}" \
        && pwsh -NonInteractive -Command "Install-Module -Name Az -RequiredVersion ${azVersion} -Scope AllUsers -Repository PSGallery"; done \
        < <(printf "%s\n" "${POWERSHELL_AZ_MODULE_VERSIONS}" | jq -r '.[]')

###########
# runtime #
###########

FROM base as act

# automatic buildx ARGs
ARG TARGETARCH

# path to local bins
ARG PATH_LOCAL_BINS

# enable pipefail and set workdir
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
WORKDIR /tmp

# Install current version of git
ARG GIT_REPO=ppa:git-core/ppa
# hadolint ignore=SC2035
RUN add-apt-repository -y "${GIT_REPO}" \
    && apt-get -y update &>/dev/null \
    && apt-get -y install --no-install-recommends \
        git \
    && printf "[safe]\n\tdirectory = *\n" | tee -a /etc/gitconfig \
    && add-apt-repository --remove "${GIT_REPO}" \
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
ARG NODE_VERSION
RUN [ "${NODE_VERSION}" != "" ] || (echo "missing build-arg NODE_VERSION" && exit 1) \
    && curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n \
        -o ~/n \
    && bash ~/n "${NODE_VERSION}" \
    && rm -rf ~/n \
    && chmod -R 777 /usr/local/lib/node_modules \
    && chmod -R 777 "${PATH_LOCAL_BINS}" \
    && npm --version \
    && node --version

# Install nvm
# hadolint ignore=SC2016,SC1091
RUN export NVM_DIR=/etc/skel/.nvm \
    && mkdir -p "${NVM_DIR}" \
    && VERSION=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r '.tag_name') \
    && curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/$VERSION/install.sh | bash \
    && echo 'NVM_DIR=$HOME/.nvm' | tee -a /etc/environment \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' | tee -a /etc/skel/.bash_profile \
    && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
    && nvm alias default system

# Install YARN
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg \
    | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" \
    | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get -y update &>/dev/null \
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

# add go
COPY --link --from=golang /usr/local/go /usr/local/go
ENV PATH=/usr/local/go/bin:${PATH}
RUN sed "s|^PATH=|PATH=/usr/local/go/bin:|mg" -i /etc/environment

# add pulumi
COPY --link --from=pulumi /root/.pulumi/bin "${PATH_LOCAL_BINS}/"

# add bicep
COPY --link --from=bicep "${PATH_LOCAL_BINS}/bicep" "${PATH_LOCAL_BINS}/bicep"

# add azcopy
COPY --link --from=azcopy "${PATH_LOCAL_BINS}/azcopy" "${PATH_LOCAL_BINS}/azcopy"
RUN ln -s azcopy "${PATH_LOCAL_BINS}/azcopy10"

# add git-lfs
COPY --link --from=git-lfs "${PATH_LOCAL_BINS}/git-lfs" "${PATH_LOCAL_BINS}/git-lfs"

# add k8s-tools
COPY --link --from=k8s-tools \
    "${PATH_LOCAL_BINS}/helm" \
    "${PATH_LOCAL_BINS}/kubectl" \
    "${PATH_LOCAL_BINS}/minikube" \
    "${PATH_LOCAL_BINS}"/

# add miniconda
ARG CONDA_PATH
ENV CONDA=${CONDA_PATH}
COPY --link --from=miniconda "${CONDA_PATH}" "${CONDA_PATH}"
RUN printf "CONDA=%s" "${CONDA_PATH}" | tee -a /etc/environment \
    && ln -s "$(realpath --relative-to="${PATH_LOCAL_BINS}" "${CONDA_PATH}/bin")/conda" "${PATH_LOCAL_BINS}/conda"

# add PyPy
COPY --link --from=pypy "${AGENT_TOOLSDIRECTORY}/PyPy" "${AGENT_TOOLSDIRECTORY}/PyPy"

# add terraform
COPY --link --from=terraform "${PATH_LOCAL_BINS}/terraform" "${PATH_LOCAL_BINS}/terraform"

# add packer
COPY --link --from=packer "${PATH_LOCAL_BINS}/packer" "${PATH_LOCAL_BINS}/packer"

# add rust
ARG CARGO_HOME
COPY --link --from=rust "${CARGO_HOME}" "${CARGO_HOME}"
ARG RUSTUP_HOME
COPY --link --from=rust "${RUSTUP_HOME}" "${RUSTUP_HOME}"
ENV PATH=${CARGO_HOME}/bin:${PATH} \
    CARGO_HOME=${CARGO_HOME} \
    RUSTUP_HOME=${RUSTUP_HOME}
RUN sed "s|^PATH=|PATH=${CARGO_HOME}/bin:|mg" -i /etc/environment \
    && echo "CARGO_HOME=${CARGO_HOME}" | tee -a /etc/environment \
    && echo "RUSTUP_HOME=${RUSTUP_HOME}" | tee -a /etc/environment

# add PowerShell
ARG TOOL_PATH_PWSH=/usr/share/powershell
COPY --link --from=dotnet-powershell "${TOOL_PATH_PWSH}" "${TOOL_PATH_PWSH}"
RUN ln -s "$(realpath --relative-to="${PATH_LOCAL_BINS}" "${TOOL_PATH_PWSH}")/pwsh" "${PATH_LOCAL_BINS}/pwsh"

# add  PowerShell-modules
COPY --link --from=dotnet-powershell-modules /usr/local/share/powershell /usr/local/share/powershell
COPY --link --from=dotnet-powershell-az-modules /usr/local/share/powershell /usr/local/share/powershell

ARG RUNNER
USER ${RUNNER:-root}

# No idea how to do a healthcheck for this image
HEALTHCHECK NONE
