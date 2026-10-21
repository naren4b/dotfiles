# Personal on-demand AWS learning instance (Mumbai, default AWS profile).
.RECIPEPREFIX := >
.PHONY: help ec2 ec2-start ec2-connect ec2-end ec2-check lab-local
.PHONY: launch-ec2 ssh-ec2 delete-ec2 run-my-image setup-local
.PHONY: personal-wsl-check personal-wsl-install
.PHONY: profile-check profile-install personal-wsl ofc-wsl ec2-apt ec2-yum
INSTANCE ?=
NAME ?= personal-learning-lab
PROFILE ?= personal-wsl

help:
> @echo "make ec2 NAME=my-lab        Reuse running lab or create and connect"
> @echo "make ec2-start NAME=my-lab  Create a standalone named lab"
> @echo "make ec2-connect INSTANCE=i-...  Connect to a running lab"
> @echo "make ec2-end INSTANCE=i-...      Terminate a lab"
> @echo "make ec2-check               Verify local AWS and SSM tools"
> @echo "make lab-local               Enter reusable learning container on this host"
> @echo "make launch-ec2 NAME=lab     Create Ubuntu EC2 if absent"
> @echo "make ssh-ec2 NAME=lab        SSH into existing Ubuntu EC2"
> @echo "make delete-ec2 NAME=lab     Terminate Ubuntu EC2"
> @echo "make run-my-image            Run lab container on EC2"
> @echo "make setup-local             Install dotfiles directly on Ubuntu"
> @echo "make personal-wsl-check      Check personal WSL toolchain"
> @echo "make personal-wsl-install    Install personal WSL core + CV tools"
> @echo "make profile-check PROFILE=personal-wsl  Check selected profile"
> @echo "make profile-install PROFILE=personal-wsl Install selected profile"
> @echo "Profiles: personal-wsl, ofc-wsl, ec2-apt, ec2-yum"

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

launch-ec2:
> @bash scripts/simple-ec2.sh launch "$(NAME)"

ssh-ec2:
> @bash scripts/simple-ec2.sh ssh "$(NAME)"

delete-ec2:
> @bash scripts/simple-ec2.sh delete "$(NAME)"

run-my-image:
> @bash scripts/run-my-image.sh


setup-local:
> @bash setup.sh

personal-wsl-check:
> @$(MAKE) profile-check PROFILE=personal-wsl

personal-wsl-install:
> @$(MAKE) profile-install PROFILE=personal-wsl

# One entrypoint, existing distribution-specific bootstrap scripts.
profile-check:
> @bash bootstrap/profile.sh "$(PROFILE)" check

profile-install:
> @bash bootstrap/profile.sh "$(PROFILE)" install

personal-wsl:
> @$(MAKE) profile-install PROFILE=personal-wsl

ofc-wsl:
> @$(MAKE) profile-check PROFILE=ofc-wsl

ec2-apt:
> @$(MAKE) profile-install PROFILE=ec2-apt

ec2-yum:
> @$(MAKE) profile-install PROFILE=ec2-yum
