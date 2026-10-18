# Simple EC2 learning host

On WSL, Git Bash, Linux EC2 or PowerShell with Bash/Make and AWS CLI installed:

```bash
git clone https://github.com/naren4b/dotfiles.git
cd dotfiles
cp .env.example .env
# Edit .env: AWS_KEY_NAME, SSH_CIDR (your public /32); SSH_KEY_PATH defaults to ~/Downloads/ec2-ofc
make launch-ec2 NAME=test-lab
make ssh-ec2 NAME=test-lab
make delete-ec2 NAME=test-lab
```

The default private-key location is `~/Downloads/ec2-ofc` (a file, not a directory). `AWS_KEY_NAME` must reference its matching EC2 key pair. Keep the key readable only by your user (`chmod 600 ~/Downloads/ec2-ofc`).\n\nGNU Make requires `NAME=` syntax, not `make launch-ec2 test-lab`. PowerShell requires Make and Bash installed/on PATH (or run from Git Bash). Key paths must be readable in the executing shell. EC2 uses Ubuntu 24.04 LTS, public subnet/IP, restricted port 22, a 30 GiB encrypted gp3 disk and an on-instance four-hour termination timer. There is no guarantee of AWS-side termination if cloud-init or the operating system fails; check active resources in the console.

Inside EC2:

```bash
git clone https://github.com/naren4b/dotfiles.git
cd dotfiles
cp .env.example .env
# Set LAB_ENV_FILE in .env, if an app-specific environment file is required.
make run-my-image
```

The image is built locally from `containers/learning/Containerfile`, and the workspace `~/projects` is mounted at `/workspace`. Lab agents install additional dependencies inside their own lab image or setup workflow. No GitHub tokens are required to clone the public dotfiles repository. Never commit `.env`, `lab.env`, or private keys.

**Security:** `--network host` shares the EC2 host network namespace. Docker access via sudo is root-equivalent. Container uses `--cap-drop=ALL`, `--security-opt no-new-privileges` and no `--privileged`. Environment injection is opt-in via LAB_ENV_FILE; do not include unrelated secrets in it. The container is stopped after four hours or when you exit; the host has its own four-hour shutdown safeguard.

## Configurable time limit

Set `LAB_HOURS=4` in the launcher's `.env` (allowed values: 1 through 99). The EC2 launcher converts this to a systemd shutdown timer with EC2 terminate-on-shutdown. On the EC2 instance, use the same setting in its local `.env` to limit `make run-my-image` with `timeout`. The two `.env` files are independent, so set both if changing the default. This is best-effort and not AWS-enforced expiry.

## AWS authentication: laptop, EC2 and Docker

- **Laptop/WSL:** Configure a local AWS profile with `aws configure sso` when IAM Identity Center is available, or use approved short-lived credentials. Check `aws sts get-caller-identity` before creating instances. Never place AWS access keys in `.env`.
- **Ubuntu EC2:** Attach an existing least-privilege IAM instance profile to the instance. The current simple Ubuntu launcher does **not** attach a role automatically. In EC2 Console select **Instances → Actions → Security → Modify IAM role**. Do not create administrator credentials or add permanent access keys to disposable hosts.
- **After running `aws configure` on EC2:** `aws configure list` shows where settings are loaded from; `aws sts get-caller-identity` shows which identity is active. A static key in `~/.aws/credentials` can take precedence over the instance profile. After successfully attaching/testing the role, remove the static keys from the disposable EC2 (do not blindly delete shared configuration on other machines).
- **Docker:** `run-my-image` uses host networking. EC2 role credentials may be discovered via IMDS if it is enabled and reachable. Access to instance metadata from a container is security-sensitive: only trusted lab images and users, and role permissions restricted to the lab's need. Never bind-mount `~/.aws` or pass credential variables by default.

Check on the EC2 host:

```bash
aws --version
aws configure list
aws sts get-caller-identity
```

The `make setup-local` target runs shared `setup.sh` which installs the official AWS CLI v2 if missing (pending the related setup PR until merged). For S3, KMS or other AWS lab APIs, request scoped permissions on the instance role, not long-term IAM user access keys.

References: [AWS EC2 instance roles](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html), [Attach an IAM role](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/attach-iam-role.html).
