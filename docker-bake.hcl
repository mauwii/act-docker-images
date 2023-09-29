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
  default = and(notequal(GITHUB_BASE_REF, null), notequal(GITHUB_BASE_REF, "")) ? "${GITHUB_BASE_REF}" : and(notequal(GITHUB_REF_NAME, null), notequal(GITHUB_REF_NAME, "")) ? "${GITHUB_REF_NAME}" : "local"
}

variable "GITHUB_REF_NAME" {
  default = null
}

variable "GITHUB_BASE_REF" {
  default = null
}

variable "GITHUB_ACTOR" {
  default = GITHUB_REPOSITORY_OWNER
}

variable "FROM_IMAGE" {
  default = "buildpack-deps"
}

variable "BICEP_VERSION" {
  default = "v0.21.1"
}

variable "DOTNET_SDK_VERSION" {
  default = "6.0.414"
}

variable "DEPENDENCIES" {
  default = "[\"acl\",\"apt-transport-https\",\"aria2\",\"bison\",\"brotli\",\"dbus\",\"dnsutils\",\"fakeroot\",\"flex\",\"fonts-noto-color-emoji\",\"ftp\",\"gawk\",\"gnupg-agent\",\"gnupg2\",\"haveged\",\"iproute2\",\"iputils-ping\",\"libc++-dev\",\"libc++abi-dev\",\"libc6-dev\",\"libgbm-dev\",\"libgconf-2-4\",\"libgsl-dev\",\"libgtk-3-0\",\"libmagic-dev\",\"libsecret-1-dev\",\"libssl-dev\",\"libunwind8\",\"libxkbfile-dev\",\"libxss1\",\"libyaml-dev\",\"lz4\",\"mediainfo\",\"net-tools\",\"netcat\",\"p7zip-full\",\"p7zip-rar\",\"parallel\",\"pass\",\"patchelf\",\"pigz\",\"pollinate\",\"python-is-python3\",\"rpm\",\"rsync\",\"shellcheck\",\"software-properties-common\",\"sphinxsearch\",\"sqlite3\",\"ssh\",\"sshpass\",\"subversion\",\"sudo\",\"swig\",\"telnet\",\"texinfo\",\"time\",\"tk\",\"unzip\",\"upx\",\"xorriso\",\"xvfb\",\"xz-utils\",\"zip\",\"zstd\",\"zsync\"]"
}

variable "GO_VERSION" {
  default = "1.20.8"
}

variable "GOLANG_GITHUB_SHA256_amd64" {
  default = "cc97c28d9c252fbf28f91950d830201aa403836cbed702a05932e63f7f0c7bc4"
}

variable "GOLANG_GITHUB_SHA256_arm64" {
  default = "15ab379c6a2b0d086fe3e74be4599420e66549edf7426a300ee0f3809500f89e"
}

variable "NODE_VERSION" {
  default = "20"
}

variable "PULUMI_VERSION" {
  default = "3.86.0"
}

variable "POWERSHELL_AZ_MODULE_VERSIONS" {
  default = "[\"9.3.0\"]"
}

variable "POWERSHELL_VERSION" {
  default = "7.2.13"
}

variable "POWERSHELL_MODULES" {
  default = "[\"MarkdownPS\",\"Microsoft.Graph\",\"Pester\",\"PSScriptAnalyzer\"]"
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
        major    = "22"
        minor    = "04"
        codename = "jammy"
      },
      {
        major    = "20"
        minor    = "04"
        codename = "focal"
      }
    ]
  }
  args = {
    BICEP_VERSION                 = BICEP_VERSION
    CODENAME                      = release.codename
    DEPENDENCIES                  = DEPENDENCIES
    DISTRO                        = "ubuntu"
    DOTNET_SDK_VERSION            = DOTNET_SDK_VERSION
    FROM_IMAGE                    = FROM_IMAGE
    FROM_VERSION_MAJOR            = release.major
    FROM_VERSION_MINOR            = release.minor
    GO_VERSION                    = GO_VERSION
    GOLANG_GITHUB_SHA256_amd64    = GOLANG_GITHUB_SHA256_amd64
    GOLANG_GITHUB_SHA256_arm64    = GOLANG_GITHUB_SHA256_arm64
    NODE_VERSION                  = NODE_VERSION
    POWERSHELL_AZ_MODULE_VERSIONS = POWERSHELL_AZ_MODULE_VERSIONS
    POWERSHELL_MODULES            = POWERSHELL_MODULES
    PULUMI_VERSION                = PULUMI_VERSION
    TOOL_PATH_PWSH                = "/usr/share/powershell"
  }
  name = "ubuntu-act-${release.codename}"
  cache-from = [
    "${REGISTRY}/${GITHUB_REPOSITORY_OWNER}/ubuntu-act:cache-${release.codename}"
  ]
  cache-to = [
    notequal(REF_NAME, "local") ? "${REGISTRY}/${GITHUB_REPOSITORY_OWNER}/ubuntu-act:cache-${release.codename}" : ""
  ]
  tags = [
    "${REGISTRY}/${GITHUB_REPOSITORY_OWNER}/ubuntu-act:${release.major}.${release.minor}-${REF_NAME}",
    and(notequal(GITHUB_SHA, null), equal("${REF_NAME}", "main")) ? "${REGISTRY}/${GITHUB_REPOSITORY_OWNER}/ubuntu-act:${release.major}.${release.minor}-${substr(GITHUB_SHA, 0, 7)}" : "",
    equal("${REF_NAME}", "main") ? "${REGISTRY}/${GITHUB_REPOSITORY_OWNER}/ubuntu-act:${release.major}.${release.minor}" : "",
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
