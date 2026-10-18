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

For local WSL or any other Linux host with Podman:
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
