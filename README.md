# Guest OS
```bash
apt-get update -y
findmnt
/media/nabh/VBox_GAs_7.0.12/VBoxLinuxAdditions.run
reboot
```
# Install docker 
```bash
apt-get install docker.io
sudo chmod 666 /var/run/docker.sock
systemctl restart docker.service

```

# Get the sudo access 
```bash
sudo adduser naren
sudo usermod -aG sudo naren
sudo visudo
naren ALL = NOPASSWD : ALL

ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub root@127.0.1.1

```

# Utility Software
```bash
apt-get install git curl vim python3-pip yq tree openssh-client openssh-server docker.io
apt-get --allow-unauthenticated update
apt-get --allow-unauthenticated install -y bash-completion binutils
echo 'colorscheme ron' >>~/.vimrc
echo 'set tabstop=2' >>~/.vimrc
echo 'set shiftwidth=2' >>~/.vimrc
echo 'set expandtab' >>~/.vimrc
echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'alias c=clear' >>~/.bashrc
echo 'complete -F __start_kubectl k' >>~/.bashrc
sed -i '1s/^/force_color_prompt=yes\n/' ~/.bashrc
source ~/.bashrc
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[33m\]$(__git_ps1 " (%s)")\[\033[00m\] \$ '
```
# Set my Prompt 
Add this to the `~/.bashrc`

```
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[33m\]$(__git_ps1 " (%s)")\[\033[00m\] \$ '

```

# Install Python 

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install build-essential software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update -y
sudo apt install python3 -y
sudo apt install -y python-is-python3
python --version

python3 --version
alias python=python3

# Creates the virtual environment and creates the directory '.venv'
# pyvenv.cfg file inside your .venv folder and change the line `include-system-site-packages = false` to `true`. 
# pip cache dir
python -m venv .venv --system-site-packages
source .venv/bin/activate

pip install -r requirements.txt
python app.py 

pip install ruff 
# ruff format <filename>
```
# Install Go
```
VERSION=1.25.5 # https://go.dev/doc/install
wget https://go.dev/dl/go1.25.5.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.25.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
go 
```

# aws cli
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```
# kubectl
```bash

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# For AWS kubectl  https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html#kubectl-install-update
# curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.34.2/2025-11-13/bin/darwin/amd64/kubectl
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
echo 'export PATH=$HOME/bin:$PATH' >>~/.bashrc
kubectl version --client

sudo apt-get install bash-completion
sudo apt install fzf
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
```
# plugins
```bash
echo -e '#!/bin/bash\n\nkubectl get pods -A -o custom-columns='NAME:metadata.name,IMAGES:spec.containers[*].image'' > kubectl-all-images
sudo chmod +x ./kubectl-all-images
sudo mv ./kubectl-all-images /usr/local/bin
kubectl plugin list
kubectl all images
```
# Debug
```bash
# Run a pod 
kubectl run ephemeral-demo --image=registry.k8s.io/pause:3.1 --restart=Never
kubectl run -i --rm --tty debug --image=alpine --restart=Never -- sh
apk add --update bind-tools net-tools openssl curl git python3 go 

#Attach the debug pod 
#kubectl debug -it <pod-name> --image=busybox:1.28 --target=<container-name>

kubectl debug -it ephemeral-demo --image=busybox:1.28 --target=ephemeral-demo
```

# helm
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh


```

# Kind Cluster
```bash
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind


kind create cluster
kubectl get nodes
alias k=kubectl
source /etc/bash_completion
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >>~/.bashrc
complete -o default -F __start_kubectl k
```
# kubectl 

https://gist.githubusercontent.com/rothgar/a2092f73b06465ddda0e855cc1f6ec2b/raw/3dde648fc2ff8ad08a8cf15308950caa2dfeabc2/k8s.zsh

# Terraform 
```bash
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
terraform -install-autocomplete
#vi ~/.bashrc
complete -C /usr/bin/terraform terraform
alias tf=terraform
complete -C '/usr/bin/terraform' tf
```

# ArgoCD
```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

kind create cluster
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
nohup kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0 & 
argocd login localhost:8080 --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo) --insecure

# DIY Deploy the application 
argocd app create helm-guestbook \
    --repo https://github.com/argoproj/argocd-example-apps.git \
    --path helm-guestbook \
    --dest-namespace default \
    --dest-server https://kubernetes.default.svc 

argocd app sync guestbook --dry-run 
```

