# Portable development baseline

Goal: the same Git, Python, Terraform, AWS CLI and Podman workflow on a Windows laptop, Ubuntu VM or EC2.

## Layout

| Host | Editor | Shell and tools | Working directory |
| --- | --- | --- | --- |
| Windows + WSL2 | Windows VS Code/Cursor | Ubuntu WSL | `~/projects` in WSL |
| Ubuntu VM | Local/remote editor | Ubuntu | `~/projects` |
| Ubuntu EC2 | Remote SSH editor | Ubuntu | `~/projects` |

Use one Linux CLI toolchain per active environment. Keep IDE-only packages on Windows. Do not install Docker Desktop, Podman Desktop or extra WSL distributions solely for this setup. VMs and EC2 have their own remote storage by design; share code through Git instead of copying virtual disks.

## Install

Run on each Ubuntu WSL/VM/EC2 host:

```bash
git clone https://github.com/naren4b/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap/ubuntu-minimal.sh
./install.sh
./doctor.sh
./scripts/storage-report.sh
```

For feature branches, check out the review branch before running. The existing `bootstrap/ubuntu.sh` remains an optional full-stack installer and may install additional tools.

Never commit access tokens or SSH keys. Prefer AWS IAM roles on EC2 and supported SSO profiles on laptops. Preserve existing `~/.bashrc.local` and `~/.gitconfig.local`.

## Windows WSL memory

For a **32 GB RAM, 512 GB SSD** laptop, use `config/windows/wslconfig` as a template. Copy it to `%USERPROFILE%\\.wslconfig` **only after reviewing any existing file**. Then run `wsl --shutdown` from PowerShell. It applies to all WSL2 distributions, not to EC2 or ordinary VMs.

Suggested limits: 12 GB memory, 2 GB swap, automatic memory reclaim. These are limits, not fixed reservations. Keep roughly 80 GB free on Windows if practical. Monitor actual usage rather than pre-allocating a 100 GB virtual disk.

Keep source in WSL's Linux filesystem, not a duplicate clone under `C:\\`. Rootless Podman stores images in the user's Linux home. Terraform shares its provider download cache through `~/.terraformrc` when no prior configuration exists.

## Troubleshooting watches

For `Failed to allocate directory watch: Too many open files`, first inspect:

```bash
cat /proc/sys/fs/inotify/max_user_watches
cat /proc/sys/fs/inotify/max_user_instances
ulimit -n
```

If inotify limits are exhausted, apply the optional settings in `config/linux/99-inotify.conf`:

```bash
sudo install -m 0644 config/linux/99-inotify.conf /etc/sysctl.d/99-inotify.conf
sudo sysctl --system
```

These changes require root and should be applied only to hosts that need them. Diagnose actual open file-descriptor exhaustion separately. On EC2, also inspect service-level limits before raising them.

## Safe cleanup

```bash
./scripts/storage-report.sh
./scripts/podman-cleanup.sh
```

The cleanup only prunes dangling Podman images after confirmation. Do not automatically prune volumes, force-remove all images or delete Terraform provider caches. Cleaning Linux files may not immediately shrink Windows' WSL VHDX file; back up before attempting any disk compaction.
