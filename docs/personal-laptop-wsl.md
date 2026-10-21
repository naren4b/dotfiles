# Personal laptop WSL profile

Target: Ubuntu 24.04 WSL. Keep personal development separate from
corporate Git, credentials, proxy and CA settings.

## Tools

| Group | Tools |
| --- | --- |
| Base | Git, SSH, curl, wget, ca-certificates, jq, zip, unzip, Make |
| Python | Python 3.12, pip, venv, pipx |
| AI | nvm, Node.js LTS, npm, Codex CLI |
| GitHub | gh and SSH |
| CV release | Playwright Chromium installed in my-cv venv |
| Optional cloud | AWS CLI v2, Terraform, kubectl, Helm, Podman |
| Optional extended | OpenTofu, Terragrunt, Ansible, glab |

## Setup

Clone the repositories into `~/ws/personal`. Install nvm once using
its [official setup instructions](https://github.com/nvm-sh/nvm).

```bash
cd ~/ws/personal
git clone git@github.com:naren4b/dotfiles.git
git clone git@github.com:naren4b/my-cv.git
cd dotfiles
make profile-check PROFILE=personal-wsl
make profile-install PROFILE=personal-wsl
```

The install command does not install optional cloud lab tools.
For these, use `bootstrap/ubuntu-minimal.sh` (AWS/Terraform/Podman)
or `bootstrap/ubuntu.sh` (extended tools). Do not install duplicate
container runtimes solely for this profile.

Playwright Chromium uses the supported browser installation.
If downloads fail, diagnose access to the official host rather than
weakening the canonical CV PDF validation.

## Identity and safety

Personal Git author and committer email must be
`panda.narendra@gmail.com`; verify both before making commits.

```bash
git -C ~/ws/personal/my-cv var GIT_AUTHOR_IDENT
git -C ~/ws/personal/my-cv var GIT_COMMITTER_IDENT
```

Keep corporate repositories under `~/ws/company` and configure their
identity separately using `company/gitconfig.local.example`.
This profile does not overwrite `~/.gitconfig`, authentication,
SSH keys, proxy settings, credentials or corporate config.

## Validate

```bash
make profile-check PROFILE=personal-wsl
cd ~/ws/personal/my-cv
.venv/bin/python cv-architect-v2/scripts/cv2.py dependencies
.venv/bin/python -m unittest discover -s cv-architect-v2/tests -v
```

No release approvals, CIBC application records or Drive files are changed.
