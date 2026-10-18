# Simple EC2 learning host

On WSL, Git Bash, Linux EC2 or PowerShell with Bash/Make and AWS CLI installed:

```bash
git clone https://github.com/naren4b/dotfiles.git
cd dotfiles
cp .env.example .env
# Edit .env: AWS_KEY_NAME, SSH_KEY_PATH, SSH_CIDR (your public /32)
make launch-ec2 NAME=test-lab
make ssh-ec2 NAME=test-lab
make delete-ec2 NAME=test-lab
```

GNU Make requires `NAME=` syntax, not `make launch-ec2 test-lab`. PowerShell requires Make and Bash installed/on PATH (or run from Git Bash). Key paths must be readable in the executing shell. EC2 uses Ubuntu 24.04 LTS, public subnet/IP, restricted port 22, a 30 GiB encrypted gp3 disk and an on-instance four-hour termination timer. There is no guarantee of AWS-side termination if cloud-init or the operating system fails; check active resources in the console.

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
