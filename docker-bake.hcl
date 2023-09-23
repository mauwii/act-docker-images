variable "REGISTRY" {
  default = "docker.io"
}

variable "REPOSITORY_OWNER" {
  default = "mauwii"
}

variable "REPOSITORY" {
  default = "${REPOSITORY_OWNER}/act-docker-images"
}

variable "GITHUB_SHA" {
  default = null
}

variable "REF_NAME" {
  default = notequal(GITHUB_BASE_REF, "") ? "${GITHUB_BASE_REF}" : "${GITHUB_REF_NAME}"
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
  attest = [
    "type=provenance,mode=max",
    "type=sbom"
  ]
  dockerfile = "linux/ubuntu/Dockerfile"
  platforms = ["linux/amd64", "linux/arm64"]
  matrix = {
    distro = [
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
    FROM_VERSION_MAJOR = distro.major
    FROM_VERSION_MINOR = distro.minor
    CODENAME = distro.codename
    GO_VERSION = "${GO_VERSION}"
    GOLANG_GITHUB_SHA256_amd64 = "${GOLANG_GITHUB_SHA256_amd64}"
    GOLANG_GITHUB_SHA256_arm64 = "${GOLANG_GITHUB_SHA256_arm64}"
  }
  name = "ubuntu-act-${distro.codename}"
  cache-from = [
    "${REGISTRY}/${REPOSITORY_OWNER}/ubuntu-act:cache-${distro.codename}-amd64",
    "${REGISTRY}/${REPOSITORY_OWNER}/ubuntu-act:cache-${distro.codename}-arm64",
    "${REGISTRY}/${REPOSITORY_OWNER}/ubuntu-act:cache-${distro.codename}",
  ]
  tags = [
    "${REGISTRY}/${REPOSITORY_OWNER}/ubuntu-act:${distro.major}.${distro.minor}-${REF_NAME}",
    notequal(GITHUB_SHA,"") ? "${REGISTRY}/${REPOSITORY_OWNER}/ubuntu-act:${distro.major}.${distro.minor}-${substr(GITHUB_SHA, 0, 7)}" : "",
    equal("${REF_NAME}", "main") ? "${REGISTRY}/${REPOSITORY_OWNER}/ubuntu-act:${distro.major}.${distro.minor}" : "",
    and(equal("${REF_NAME}", "main"),equal(distro.codename, "jammy")) ? "${REGISTRY}/${REPOSITORY_OWNER}/ubuntu-act:latest" : "",
  ]
  labels = {
    "org.opencontainers.image.source" = "https://github.com/${REPOSITORY}"
    "org.opencontainers.image.revision" = "${GITHUB_SHA}"
    "org.opencontainers.image.vendor" = "${REPOSITORY_OWNER}"
  }
}
