FROM ubuntu:24.04

ARG AWS_CLI_VERSION=2.31.0
ARG TERRAFORM_VERSION=1.13.5
ARG KUBECTL_VERSION=v1.35.9
ARG HELM_VERSION=v3.20.2

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates curl dnsutils gh git iproute2 iputils-ping jq less \
       netcat-openbsd openssh-client openssl postgresql-client unzip \
    && rm -rf /var/lib/apt/lists/*

RUN set -eu; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) aws_arch=x86_64 ;; \
      arm64) aws_arch=aarch64 ;; \
      *) echo "Unsupported toolbox architecture: $arch" >&2; exit 1 ;; \
    esac; \
    tmp="$(mktemp -d)"; \
    trap 'rm -rf "$tmp"' EXIT; \
    cd "$tmp"; \
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${aws_arch}-${AWS_CLI_VERSION}.zip" -o aws.zip; \
    unzip -q aws.zip; \
    ./aws/install; \
    tf_base="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}"; \
    tf_zip="terraform_${TERRAFORM_VERSION}_linux_${arch}.zip"; \
    curl -fsSLO "${tf_base}_linux_${arch}.zip"; \
    curl -fsSL "${tf_base}_SHA256SUMS" -o terraform-checksums; \
    grep -F "  ${tf_zip}" terraform-checksums > terraform-checksum; \
    sha256sum -c terraform-checksum; \
    unzip -q "$tf_zip" terraform; \
    install -m 0755 terraform /usr/local/bin/terraform; \
    kube_base="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${arch}/kubectl"; \
    curl -fsSLO "$kube_base"; \
    curl -fsSL "${kube_base}.sha256" -o kubectl.sha256; \
    printf '%s  kubectl\n' "$(cat kubectl.sha256)" | sha256sum -c -; \
    install -m 0755 kubectl /usr/local/bin/kubectl; \
    helm_archive="helm-${HELM_VERSION}-linux-${arch}.tar.gz"; \
    curl -fsSLO "https://get.helm.sh/${helm_archive}"; \
    curl -fsSL "https://get.helm.sh/${helm_archive}.sha256" -o helm.sha256; \
    printf '%s  %s\n' "$(cat helm.sha256)" "$helm_archive" | sha256sum -c -; \
    tar -xzf "$helm_archive" "linux-${arch}/helm"; \
    install -m 0755 "linux-${arch}/helm" /usr/local/bin/helm

ENV HOME=/tmp \
    AWS_EC2_METADATA_DISABLED=true \
    AWS_PAGER=""
WORKDIR /work
USER 65534:65534
CMD ["bash"]
