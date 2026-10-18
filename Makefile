# Personal on-demand AWS learning instance (Mumbai, default AWS profile).
.RECIPEPREFIX := >
.PHONY: help ec2 ec2-start ec2-connect ec2-end ec2-check
INSTANCE ?=

help:
> @echo "make ec2                     Launch, connect and terminate when session exits"
> @echo "make ec2-start               Start a standalone lab"
> @echo "make ec2-connect INSTANCE=i-...  Connect to a running lab"
> @echo "make ec2-end INSTANCE=i-...      Terminate a lab"
> @echo "make ec2-check               Verify local AWS and SSM tools"

ec2:
> @bash scripts/ec2-learning-lab.sh lab

ec2-start:
> @bash scripts/ec2-learning-lab.sh start

ec2-connect:
> @test -n "$(INSTANCE)" || { echo "ERROR: Pass INSTANCE=i-..." >&2; exit 2; }
> @bash scripts/ec2-learning-lab.sh connect "$(INSTANCE)"

ec2-end:
> @test -n "$(INSTANCE)" || { echo "ERROR: Pass INSTANCE=i-..." >&2; exit 2; }
> @bash scripts/ec2-learning-lab.sh end "$(INSTANCE)"

ec2-check:
> @bash scripts/verify-baseline.sh
