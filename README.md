# dotfiles

Version-controlled shell, Git, and toolchain setup for **Windows + WSL2**, **Ubuntu VMs**, and **EC2**.

**IDE (Cursor / VS Code) runs on Windows.** Linux hosts get CLI tools and the same shell look-and-feel. Company secrets and machine-specific settings stay in `~/.bashrc.local` and `~/.gitconfig.local` (never overwritten by install).

## Start here: portable baseline (recommended)

Lean stack: Git, Python 3, Terraform (shared provider cache), rootless Podman, AWS CLI v2. No Docker Desktop and no world-writable Docker socket.

Full guide: **[docs/portable-development.md](docs/portable-development.md)**

```bash
git clone https://github.com/naren4b/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Ubuntu WSL, VM, or EC2
bash bootstrap/ubuntu-minimal.sh
bash install.sh
bash doctor.sh
bash scripts/storage-report.sh
```

**Windows WSL memory (optional):** review and copy [config/windows/wslconfig](config/windows/wslconfig) to `%USERPROFILE%\.wslconfig`, then `wsl --shutdown`.

**Containers:** rootless Podman only — see [podman-setup.md](podman-setup.md). Do not use `chmod 666` on `/var/run/docker.sock`.

## Full stack (optional)

Extra tools (kubectl, Helm, OpenTofu, Terragrunt, `gh`, `glab`, and more): [bootstrap/README.md](bootstrap/README.md)

```bash
powershell -ExecutionPolicy Bypass -File bootstrap/windows.ps1   # Windows
bash bootstrap/ubuntu.sh                                         # Ubuntu / WSL
```

## Maintain and verify

```bash
bash dry-run.sh                    # live vs repo vs GitHub (no writes)
bash harvest.sh                    # Windows: capture IDE/shell into config/
bash company/verify-company.sh     # read-only company overlay check
```

Company placeholders (no secrets): `company/*.example`

After a look-and-feel change on Windows, run `harvest.sh`, then commit and push.

## Other docs

| Doc | Purpose |
| --- | --- |
| [docs/portable-development.md](docs/portable-development.md) | Cross-host layout, inotify, storage cleanup |
| [bootstrap/README.md](bootstrap/README.md) | One-click full Windows + Ubuntu stack |
| [cursor-system-setup.md](cursor-system-setup.md) | Cursor on Windows with WSL |
| [docs/legacy-notes.md](docs/legacy-notes.md) | Archived manual install snippets (prefer bootstrap scripts) |
