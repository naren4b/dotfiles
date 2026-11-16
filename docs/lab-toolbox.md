# Shared lab toolbox

Use one toolbox across learning repos on Ubuntu 24.04 in WSL2 or on a VM.
The image is built locally from the [Dockerfile](../toolbox/Dockerfile)
for amd64 or arm64. The [portable baseline](portable-development.md)
sets up rootless Podman. Skip the bootstrap if Podman already works.

## Included tools

| Tool | Use |
| --- | --- |
| AWS CLI v2 | Inspect AWS identity, services and resources |
| Terraform | Format, validate and plan infrastructure |
| kubectl, Helm 3 and Helm 4 (`helm4`) | Inspect Kubernetes and render charts while keeping Helm 3 compatible |
| Git and GitHub CLI | Inspect source and work with GitHub PRs |
| Docker CLI and KIND | Inspect containers and create local Kubernetes clusters when a host Docker daemon is explicitly provided |
| Argo CD CLI | Inspect and manage Argo CD with explicit cluster access |
| PostgreSQL client | Connect with `psql` and inspect databases |
| jq | Filter JSON output |
| curl, dig, ip, ss, ping, nc, openssl, ssh | Debug HTTP, DNS, routes, sockets, TLS and SSH |

The portable bootstrap installs Git, AWS CLI v2, Terraform and Podman.
The [full Ubuntu bootstrap](../bootstrap/ubuntu.sh) also attempts kubectl,
Helm and GitHub CLI. Neither bootstrap explicitly installs `psql` or `jq`.
The toolbox includes both. If you need them on the host, install the
client packages in Ubuntu.

```bash
sudo apt-get update
sudo apt-get install -y postgresql-client jq
psql --version
jq --version
```

## Build and verify

Run from your `dotfiles` checkout. The build downloads tools and needs
internet access. The version check runs offline, without credentials.

```bash
podman build -t localhost/lab-toolbox:local toolbox
podman run --rm --network=none localhost/lab-toolbox:local bash -ec '
  aws --version
  terraform version
  kubectl version --client
  helm version --short
  helm4 version --short
  docker --version
  kind version
  argocd version --client
  git --version
  gh --version
  psql --version
  jq --version
  command -v curl dig ip ss ping nc openssl ssh
'
```

The Dockerfile pins AWS CLI, Terraform, kubectl, Helm 3, Helm 4, KIND and Argo CD CLI. Match Terraform
to the lab module and kubectl to the target cluster before connecting.
Rebuild with reviewed version overrides when a project needs other versions.

## Use from any learning repo

Run from the root of the learning repo. The shell runs as your mapped host
user and the checkout is read-only. Use the host for tasks that need to
write project files or initialize a Terraform backend.

```bash
podman run --rm -it --userns=keep-id \
  --mount "type=bind,src=$PWD,dst=/work,ro" \
  localhost/lab-toolbox:local
```

## Credentials and local files

The toolbox starts with no credential mounts. The build context is limited
to the Dockerfile. Keep credentials, AWS config, kubeconfig, Terraform
state and plans outside the image and Git. Keep Docker sockets and nested
container engines out of the toolbox.

For an explicit AWS check, mount only the needed config and credential
files read-only. This example expects a short-lived `lab` profile in
dedicated local files. Use the host for SSO login and refresh.

```bash
podman run --rm --userns=keep-id \
  --mount "type=bind,src=$HOME/.aws/lab-config,dst=/tmp/lab-config,ro" \
  --mount "type=bind,src=$HOME/.aws/lab-credentials,dst=/tmp/lab-credentials,ro" \
  -e AWS_CONFIG_FILE=/tmp/lab-config \
  -e AWS_SHARED_CREDENTIALS_FILE=/tmp/lab-credentials \
  -e AWS_PROFILE=lab localhost/lab-toolbox:local aws sts get-caller-identity
```

For Kubernetes, mount only a dedicated kubeconfig with a read-only bind
mount and set `KUBECONFIG` to its path inside the container. An EKS config
with an AWS exec helper also needs the intended AWS profile. Read-only
mounts protect local files. IAM and Kubernetes permissions control what
the tools can change remotely.


## Kubernetes and Docker workflows

The default image is a CLI toolbox, not a Docker-in-Docker image.
It does **not** run a Docker daemon or create a Kubernetes cluster.
Helm 3 remains `helm`; Helm 4 is `helm4` so older labs do not break.

```bash
# Run commands against an explicitly mounted kubeconfig.
podman run --rm -it --userns=keep-id \
  --mount "type=bind,src=$PWD,dst=/work,ro" \
  --mount "type=bind,src=$HOME/.kube/config,dst=/tmp/kubeconfig,ro" \
  -e KUBECONFIG=/tmp/kubeconfig \
  localhost/lab-toolbox:local kubectl get nodes
```

For KIND, use the Docker CLI and KIND **on the host** by default.
KIND needs a working Docker or Podman provider, and the toolbox has no
daemon by design. Do not automatically mount `/var/run/docker.sock`.
Giving a container access to the Docker socket effectively grants
host-level control, even if the image starts as a non-root user.

The build accepts version overrides with `--build-arg` for
`KIND_VERSION`, `ARGOCD_VERSION` and `HELM4_VERSION`.
Test CLI compatibility with each cluster and chart before upgrading.
