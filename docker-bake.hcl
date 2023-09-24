variable "REGISTRY" {
  default = "docker.io"
}

variable "REPOSITORY_OWNER" {
  default = "mauwii"
}

variable "REPOSITORY" {
  default = "${REPOSITORY_OWNER}/act-docker-images"
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

variable "FROM_IMAGE" {
  default = "buildpack-deps"
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

group "default" {
  targets = ["ubuntu"]
  context = "."
}

target "ubuntu" {
  inherits = ["linux-platforms"]
  attest = [
    "type=provenance,mode=max",
    "type=sbom"
  ]
  dockerfile = "linux/ubuntu/Dockerfile"
  matrix = {
    release = [
      {
        major = "22"
        minor = "04"
        codename = "jammy"
      },
      {
        major = "20"
        minor = "04"
        codename = "focal"
      }
    ]
  }
  args = {
    DISTRO = "ubuntu"
    FROM_IMAGE = "${FROM_IMAGE}"
    FROM_VERSION_MAJOR = release.major
    FROM_VERSION_MINOR = release.minor
    CODENAME = release.codename
    GO_VERSION = "${GO_VERSION}"
    GOLANG_GITHUB_SHA256_amd64 = "${GOLANG_GITHUB_SHA256_amd64}"
    GOLANG_GITHUB_SHA256_arm64 = "${GOLANG_GITHUB_SHA256_arm64}"
  }
  name = "ubuntu-act-${release.codename}"
  cache-from = [
    "${REGISTRY}/${REPOSITORY_OWNER}/ubuntu-act:cache-${release.codename}"
  ]
  cache-to = [
    notequal(REF_NAME, "local") ? "${REGISTRY}/${REPOSITORY_OWNER}/ubuntu-act:cache-${release.codename}" : ""
  ]
  tags = [
    "${REGISTRY}/${REPOSITORY_OWNER}/ubuntu-act:${release.major}.${release.minor}-${and(notequal(REF_NAME, ""),notequal(REF_NAME, null))?REF_NAME:"local"}",
    and(notequal(GITHUB_SHA,null),equal("${REF_NAME}", "main")) ? "${REGISTRY}/${REPOSITORY_OWNER}/ubuntu-act:${release.major}.${release.minor}-${substr(GITHUB_SHA, 0, 7)}" : "",
    equal("${REF_NAME}", "main") ? "${REGISTRY}/${REPOSITORY_OWNER}/ubuntu-act:${release.major}.${release.minor}" : "",
    and(equal("${REF_NAME}", "main"),equal(release.codename, "jammy")) ? "${REGISTRY}/${REPOSITORY_OWNER}/ubuntu-act:latest" : "",
  ]
  labels = {
    "org.opencontainers.image.authors" = REPOSITORY_OWNER
    "org.opencontainers.image.created" = timestamp()
    "org.opencontainers.image.description" = "This Image is made to be used with Nektos/act to run your GH-Workflows locally"
    "org.opencontainers.image.documentation" = REPOSITORY_URL
    "org.opencontainers.image.revision" = GITHUB_SHA
    "org.opencontainers.image.source" = and(and(notequal(REPOSITORY_URL, ""), notequal(REPOSITORY_URL, null)), and(notequal(GITHUB_SHA, ""), notequal(GITHUB_SHA, null))) ? "${REPOSITORY_URL}/blob/${GITHUB_SHA}/linux/ubuntu/Dockerfile" : null
    "org.opencontainers.image.title" = "ubuntu-act-${release.codename}"
    "org.opencontainers.image.url" = equal("${REGISTRY}", "docker.io") ? "https://hub.docker.com/r/${REPOSITORY_OWNER}/ubuntu-act" :  equal("${REGISTRY}", "ghcr.io") ? "https://github.com/${REPOSITORY}/pkgs/container/ubuntu-act" : null
    "org.opencontainers.image.vendor" = "${REPOSITORY_OWNER}"
  }
}

target "linux-platforms" {
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
}
