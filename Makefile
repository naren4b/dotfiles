# Personal on-demand AWS learning instance (Mumbai, default AWS profile).
.RECIPEPREFIX := >
.PHONY: help ec2 ec2-start ec2-connect ec2-end ec2-check lab-local
INSTANCE ?=
NAME ?= personal-learning-lab

help:
> @echo "make ec2 NAME=my-lab        Reuse running lab or create and connect"
> @echo "make ec2-start NAME=my-lab  Create a standalone named lab"
> @echo "make ec2-connect INSTANCE=i-...  Connect to a running lab"
> @echo "make ec2-end INSTANCE=i-...      Terminate a lab"
> @echo "make ec2-check               Verify local AWS and SSM tools"
> @echo "make lab-local               Enter reusable learning container on this host"

ec2:
> @bash scripts/ec2-learning-lab.sh lab "$(NAME)"

ec2-start:
> @bash scripts/ec2-learning-lab.sh start "$(NAME)"

ec2-connect:
> @test -n "$(INSTANCE)" || { echo "ERROR: Pass INSTANCE=i-..." >&2; exit 2; }
> @bash scripts/ec2-learning-lab.sh connect "$(INSTANCE)"

ec2-end:
> @test -n "$(INSTANCE)" || { echo "ERROR: Pass INSTANCE=i-..." >&2; exit 2; }
> @bash scripts/ec2-learning-lab.sh end "$(INSTANCE)"

ec2-check:
> @bash scripts/verify-baseline.sh

lab-local:
> @bash scripts/learning-container.sh
