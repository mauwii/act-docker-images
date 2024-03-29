variable "REGISTRY" {
  default = "docker.io"
}

variable "GITHUB_REPOSITORY_OWNER" {
  default = "mauwii"
}

variable "REPOSITORY" {
  default = "${GITHUB_REPOSITORY_OWNER}/act-docker-images"
}

variable "REPOSITORY_URL" {
  default = "https://github.com/${REPOSITORY}"
}

variable "GITHUB_SHA" {
  default = null
}

variable "REF_NAME" {
  default = and(notequal(GITHUB_HEAD_REF, null), notequal(GITHUB_HEAD_REF, "")) ? "${GITHUB_HEAD_REF}" : and(notequal(GITHUB_REF_NAME, null), notequal(GITHUB_REF_NAME, "")) ? "${GITHUB_REF_NAME}" : "local"
}

variable "GITHUB_REF_NAME" {
  default = null
}

variable "GITHUB_HEAD_REF" {
  default = null
}

variable "GITHUB_ACTOR" {
  default = GITHUB_REPOSITORY_OWNER
}

variable "BICEP_VERSION" {
  default = "v0.21.1"
}

variable "DEPENDENCIES" {
  default = "[\"acl\",\"apt-transport-https\",\"aria2\",\"bison\",\"brotli\",\"dbus\",\"dnsutils\",\"fakeroot\",\"flex\",\"fonts-noto-color-emoji\",\"ftp\",\"gawk\",\"gnupg-agent\",\"gnupg2\",\"haveged\",\"iproute2\",\"iputils-ping\",\"libc++-dev\",\"libc++abi-dev\",\"libc6-dev\",\"libgbm-dev\",\"libgconf-2-4\",\"libgsl-dev\",\"libgtk-3-0\",\"libmagic-dev\",\"libsecret-1-dev\",\"libssl-dev\",\"libunwind8\",\"libxkbfile-dev\",\"libxss1\",\"libyaml-dev\",\"lz4\",\"mediainfo\",\"net-tools\",\"netcat\",\"p7zip-full\",\"p7zip-rar\",\"parallel\",\"pass\",\"patchelf\",\"pigz\",\"pollinate\",\"python-is-python3\",\"rpm\",\"rsync\",\"shellcheck\",\"software-properties-common\",\"sphinxsearch\",\"sqlite3\",\"ssh\",\"sshpass\",\"subversion\",\"sudo\",\"swig\",\"telnet\",\"texinfo\",\"time\",\"tk\",\"unzip\",\"upx\",\"xorriso\",\"xvfb\",\"xz-utils\",\"zip\",\"zstd\",\"zsync\"]"
}

variable "GIT_LFS_SHA256_amd64" {
  default = "60b7e9b9b4bca04405af58a2cd5dff3e68a5607c5bc39ee88a5256dd7a07f58c"
}

variable "GIT_LFS_SHA256_arm64" {
  default = "aee90114f8f2eb5a11c1a6e9f1703a2bfcb4dc1fc4ba12a3a574c3a86952a5d0"
}

variable "GIT_LFS_VERSION" {
  default = "3.4.0"
}

variable "GOLANG_SHA256_amd64" {
  default = "ff445e48af27f93f66bd949ae060d97991c83e11289009d311f25426258f9c44"
}

variable "GOLANG_SHA256_arm64" {
  default = "2096507509a98782850d1f0669786c09727053e9fe3c92b03c0d96f48700282b"
}

variable "GOLANG_VERSION" {
  default = "1.20.14"
}

variable "NODE_VERSION" {
  default = "20"
}

variable "PULUMI_VERSION" {
  default = "3.104.2"
}

variable "POWERSHELL_AZ_MODULE_VERSIONS" {
  default = "[\"9.3.0\"]"
}

variable "POWERSHELL_MODULES" {
  default = "[\"MarkdownPS\",\"Microsoft.Graph\",\"Pester\",\"PSScriptAnalyzer\"]"
}

variable "PYPY_VERSIONS" {
  default = "[\"3.10\",\"3.9\",\"3.8\",\"3.7\"]"
}

group "default" {
  targets = [
    "ubuntu"
  ]
}

target "ubuntu" {
  inherits   = ["linux-platforms"]
  dockerfile = "linux/ubuntu/Dockerfile"
  matrix = {
    release = [
      {
        version            = "22.04"
        codename           = "jammy"
        DOTNET_CHANNEL     = "6.0"
        DOTNET_DEPS        = "[\"libicu70\",\"libssl3\",\"libunwind8\",\"libgcc-s1\",\"liblttng-ust1\"]"
        DOTNET_SDK_VERSION = "latest"
        POWERSHELL_VERSION = "7.2.13"
      },
      {
        version            = "20.04"
        codename           = "focal"
        DOTNET_CHANNEL     = "6.0"
        DOTNET_DEPS        = "[\"libicu66\",\"libssl1.1\"]"
        DOTNET_SDK_VERSION = "latest"
        POWERSHELL_VERSION = "7.2.13"
      }
    ]
  }
  args = {
    BICEP_VERSION                 = BICEP_VERSION
    CARGO_HOME                    = "/usr/local/cargo"
    CODENAME                      = release.codename
    CONDA_PATH                    = "/usr/share/miniconda"
    DEPENDENCIES                  = DEPENDENCIES
    DOTNET_CHANNEL                = release.DOTNET_CHANNEL
    DOTNET_DEPS                   = release.DOTNET_DEPS
    DOTNET_SDK_VERSION            = release.DOTNET_SDK_VERSION
    FROM_VERSION                  = release.version
    GIT_LFS_SHA256_amd64          = GIT_LFS_SHA256_amd64
    GIT_LFS_SHA256_arm64          = GIT_LFS_SHA256_arm64
    GIT_LFS_VERSION               = GIT_LFS_VERSION
    GOLANG_SHA256_amd64           = GOLANG_SHA256_amd64
    GOLANG_SHA256_arm64           = GOLANG_SHA256_arm64
    GOLANG_VERSION                = GOLANG_VERSION
    LANGUAGE                      = "en_US"
    NODE_VERSION                  = NODE_VERSION
    PATH_LOCAL_BINS               = "/usr/local/bin"
    POWERSHELL_AZ_MODULE_VERSIONS = POWERSHELL_AZ_MODULE_VERSIONS
    POWERSHELL_MODULES            = POWERSHELL_MODULES
    POWERSHELL_VERSION            = release.POWERSHELL_VERSION
    PULUMI_VERSION                = PULUMI_VERSION
    PYPY_VERSIONS                 = PYPY_VERSIONS
    RUSTUP_HOME                   = "/usr/local/rustup"
    TOOL_PATH_PWSH                = "/usr/share/powershell"
  }
  name = "ubuntu-act-${release.codename}"
  cache-from = [
    "${REGISTRY}/${GITHUB_REPOSITORY_OWNER}/ubuntu-act:cache-${release.codename}"
  ]
  cache-to = [
    and(notequal("nektos/act", GITHUB_ACTOR), notequal(REF_NAME, "local")) ? "${REGISTRY}/${GITHUB_REPOSITORY_OWNER}/ubuntu-act:cache-${release.codename}" : ""
  ]
  tags = [
    "${REGISTRY}/${GITHUB_REPOSITORY_OWNER}/ubuntu-act:${release.version}-${replace(REF_NAME, "/", "-")}",
    and(notequal(GITHUB_SHA, null), equal("${REF_NAME}", "main")) ? "${REGISTRY}/${GITHUB_REPOSITORY_OWNER}/ubuntu-act:${release.version}-${substr(GITHUB_SHA, 0, 7)}" : "",
    equal("${REF_NAME}", "main") ? "${REGISTRY}/${GITHUB_REPOSITORY_OWNER}/ubuntu-act:${release.version}" : "",
    and(equal("${REF_NAME}", "main"), equal(release.codename, "jammy")) ? "${REGISTRY}/${GITHUB_REPOSITORY_OWNER}/ubuntu-act:latest" : "",
  ]
  labels = {
    "org.opencontainers.image.authors"       = notequal(GITHUB_REPOSITORY_OWNER, GITHUB_ACTOR) ? "${GITHUB_REPOSITORY_OWNER}, ${GITHUB_ACTOR}" : GITHUB_REPOSITORY_OWNER
    "org.opencontainers.image.created"       = timestamp()
    "org.opencontainers.image.description"   = "This Image is made to be used with Nektos/act to run your GH-Workflows locally"
    "org.opencontainers.image.documentation" = REPOSITORY_URL
    "org.opencontainers.image.revision"      = GITHUB_SHA
    "org.opencontainers.image.source"        = and(and(notequal(REPOSITORY_URL, ""), notequal(REPOSITORY_URL, null)), and(notequal(GITHUB_SHA, ""), notequal(GITHUB_SHA, null))) ? "${REPOSITORY_URL}/blob/${GITHUB_SHA}/linux/ubuntu/Dockerfile" : null
    "org.opencontainers.image.title"         = "ubuntu-act-${release.codename}"
    "org.opencontainers.image.url"           = equal(REGISTRY, "docker.io") ? "https://hub.docker.com/r/${GITHUB_REPOSITORY_OWNER}/ubuntu-act" : equal("${REGISTRY}", "ghcr.io") ? "https://github.com/${REPOSITORY}/pkgs/container/ubuntu-act" : null
    "org.opencontainers.image.vendor"        = GITHUB_REPOSITORY_OWNER
  }
}

target "linux-platforms" {
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
}
