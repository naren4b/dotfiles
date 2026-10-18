# Portable container learning workspace

## Ownership
- `dotfiles`: EC2 launch/reconnect/expiry, SSM and minimal host runtime, base Containerfile and container runner
- `learn-aws`, `learn-db`, and other projects: lab-specific dependencies and instructions
- Secrets: separate interactive login, never embedded in image, user data, or repository

## EC2
From your WSL `~/dotfiles` folder:
```bash
make ec2 NAME=attestation-lab
```
It creates/reconnects the instance with the same name. In the SSM shell:
```bash
sudo cloud-init status --wait
cd ~/dotfiles
make lab-local
```
The first container startup builds the reusable image on EC2 from this repository. Later starts reuse the image while the EC2 host exists. On termination, both image and workspace are removed with the root EBS volume.

For local WSL or any other Linux host with Podman or Docker:
```bash
make lab-local
```

## Isolation
The container runs without `--privileged` and with capabilities dropped. Only the per-user projects directory is mounted. AWS credentials and Docker Hub/GitHub tokens are **not** automatically mounted. The EC2 instance role is not equivalent to credentials inside the container; explicitly review permissions and the metadata-access threat model before giving untrusted images network access. The image has utilities including Git, Python, curl, AWS CLI, kubectl, Helm, Terraform, jq and yq.

## Limits
- Build requires outbound HTTPS access. There is no published image yet, so first launch spends time building it.
- A privileged host workflow, Nitro Enclaves, Docker-in-Docker or Kubernetes-in-Docker is a separate, explicitly approved lab profile.
- The instance-side four-hour shutdown is a backup, not guaranteed AWS-side enforcement.
- Lab content and Git changes must be pushed before terminating the instance.

## Runtime permissions

EC2 uses Docker installed from the Amazon Linux 2023 repository. The user does not join the `docker` group; the runner uses `sudo docker` for daemon access. Docker daemon access is effectively root privilege, although the learning container itself starts as the calling numeric user with all Linux capabilities dropped and without `--privileged`. Review untrusted container definitions before running them. On WSL/Linux with rootless Podman, the runner prefers Podman.

## One-command Git setup

Inside the EC2 SSM shell, run `export GITHUB_TOKEN=<TOKEN>` if authenticated GitHub access is needed, then `cd ~/dotfiles && make lab-local`. This command clones `learn-aws` into `~/projects/learn-aws` if absent, using an ephemeral Git askpass helper, deletes the helper, and starts the learning container with that workspace mounted. No token is passed into the container image or Docker environment. You may `unset GITHUB_TOKEN` after the command exits. If no token is set, a public unauthenticated clone is attempted. Existing repositories are left unchanged, without an automatic pull.
