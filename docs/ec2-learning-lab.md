# AWS learning EC2

The single maintained launcher is [scripts/ec2-learning-lab.sh](scripts/ec2-learning-lab.sh).

## Usage

```bash
cd ~/dotfiles
make ec2
```

| Command | Action |
| --- | --- |
| `make ec2` | Start, open an SSM shell, terminate after the shell closes |
| `make ec2-start` | Create and print instance ID |
| `make ec2-connect INSTANCE=i-...` | Reconnect to an existing lab |
| `make ec2-end INSTANCE=i-...` | Terminate an existing lab |
| `make ec2-check` | Check local baseline dependencies |

## Defaults

Profile `default`, region `ap-south-1`, default VPC/subnet, Amazon Linux 2023, `t3.medium`, 30 GiB encrypted gp3 disk, SSM access with no inbound security-group rules. The EC2 host clones this repo and runs `install.sh`.

Prerequisites: AWS CLI v2, Session Manager plugin, valid default AWS credentials, permission to create EC2 and IAM resources, and a default VPC with a functioning outbound path. `bootstrap/install-session-manager-plugin.sh` installs the local plugin on Ubuntu/WSL (pending related PR if not yet merged).

## Shutdown and cost

Leaving the SSM session causes the controlling `make ec2` process to request termination. Cloud-init also schedules an OS shutdown after four hours, and EC2 is configured to **terminate** on instance-initiated shutdown. The timeout is not a guaranteed account-side enforcement mechanism. Confirm the final state in the AWS Console; an interrupted terminal or failed cloud-init may leave resources running. Compute, gp3, public IPv4, and data transfer may all cost money. Root EBS is deleted on termination.

To inspect instance bootstrap, use `sudo tail -f /var/log/cloud-init-output.log`. Scripts, notes and data should be persisted outside the disposable instance before exit.
