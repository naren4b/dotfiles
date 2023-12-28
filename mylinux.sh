# Guest OS
apt-get update -y
findmnt
/media/nabh/VBox_GAs_7.0.12/VBoxLinuxAdditions.run
reboot

# Utility Software
apt-get install git curl vim python3-pip yq

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

# aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version

# kubectl
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/linux/amd64/kubectl
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
echo 'export PATH=$HOME/bin:$PATH' >>~/.bashrc
kubectl version --client

# helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

python3 --version
alias python=python3

# Kind Cluster
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
apt-get install docker.io

kind create cluster
kubectl get nodes
alias k=kubectl
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >>~/.bashrc
complete -o default -F __start_kubectl k
