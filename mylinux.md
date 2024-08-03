# Guest OS
```
apt-get update -y
findmnt
/media/nabh/VBox_GAs_7.0.12/VBoxLinuxAdditions.run
reboot
```
# Install docker 
```
apt-get install docker.io
sudo chmod 666 /var/run/docker.sock
systemctl restart docker.service

```

# Get the sudo access 
```

sudo adduser naren
sudo usermod -aG sudo naren
sudo visudo
naren ALL = NOPASSWD : ALL

ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub root@127.0.1.1

```

# Utility Software
```
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
```
# aws cli
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```
# kubectl
```
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/linux/amd64/kubectl
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
```
echo -e '#!/bin/bash\n\nkubectl get pods -A -o custom-columns='NAME:metadata.name,IMAGES:spec.containers[*].image'' > kubectl-all-images
sudo chmod +x ./kubectl-all-images
sudo mv ./kubectl-all-images /usr/local/bin
kubectl plugin list
kubectl all images
```
# Debug
```
# Run a pod 
kubectl run ephemeral-demo --image=registry.k8s.io/pause:3.1 --restart=Never

#Attach the debug pod 
#kubectl debug -it <pod-name> --image=busybox:1.28 --target=<container-name>

kubectl debug -it ephemeral-demo --image=busybox:1.28 --target=ephemeral-demo
```

# helm
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

python3 --version
alias python=python3
```

# Kind Cluster
```
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind


kind create cluster
kubectl get nodes
alias k=kubectl
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >>~/.bashrc
complete -o default -F __start_kubectl k
```
# kubectl 

