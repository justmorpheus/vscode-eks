#!/bin/bash

# Warning to configure AWS credentials
echo "WARNING: Please ensure that your AWS credentials are configured before proceeding."
echo "Run 'aws configure' to set up your AWS credentials."


set -e

kubectl_version='1.27.7'
kubectl_checksum='e5fe510ba6f421958358d3d43b3f0b04c2957d4bc3bb24cf541719af61a06d79'

helm_version='3.10.1'
helm_checksum='c12d2cd638f2d066fec123d0bd7f010f32c643afdf288d39a4610b1f9cb32af3'

eksctl_version='0.164.0'
eksctl_checksum='2ed5de811dd26a3ed041ca3e6f26717288dc02dfe87ac752ae549ed69576d03e'

kubeseal_version='0.18.4'
kubeseal_checksum='2e765b87889bfcf06a6249cde8e28507e3b7be29851e4fac651853f7638f12f3'

yq_version='4.30.4'
yq_checksum='30459aa144a26125a1b22c62760f9b3872123233a5658934f7bd9fe714d7864d'

# ec2_instance_selector_version='2.4.1'
# ec2_instance_selector_checksum='dfd6560a39c98b97ab99a34fc261b6209fc4eec87b0bc981d052f3b13705e9ff'

download_and_verify () {
  url=$1
  checksum=$2
  out_file=$3

  curl --location --show-error --silent --output $out_file $url

  echo "$checksum $out_file" > "$out_file.sha256"
  sha256sum --check "$out_file.sha256"

  rm "$out_file.sha256"
}

yum install --quiet -y findutils jq tar gzip zsh git diffutils wget \
  tree unzip openssl gettext bash-completion python3 pip3 python3-pip \
  amazon-linux-extras nc yum-utils

python3 -m pip install -q awscurl urllib3

# Download & install kubectl
download_and_verify "https://dl.k8s.io/release/v$kubectl_version/bin/linux/amd64/kubectl" "$kubectl_checksum" "kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/local/bin

# Download & install helm
download_and_verify "https://get.helm.sh/helm-v$helm_version-linux-amd64.tar.gz" "$helm_checksum" "helm.tar.gz"
tar zxf helm.tar.gz
chmod +x linux-amd64/helm
mv ./linux-amd64/helm /usr/local/bin
rm -rf linux-amd64/ helm.tar.gz

# Download & install eksctl
download_and_verify "https://github.com/weaveworks/eksctl/releases/download/v$eksctl_version/eksctl_Linux_amd64.tar.gz" "$eksctl_checksum" "eksctl_Linux_amd64.tar.gz"
tar zxf eksctl_Linux_amd64.tar.gz
chmod +x eksctl
mv ./eksctl /usr/local/bin
rm -rf eksctl_Linux_amd64.tar.gz

# Download & install aws cli v2
curl --location --show-error --silent "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o -q awscliv2.zip -d /tmp
/tmp/aws/install --update
rm -rf /tmp/aws awscliv2.zip

# Download & install kubeseal
download_and_verify "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${kubeseal_version}/kubeseal-${kubeseal_version}-linux-amd64.tar.gz" "$kubeseal_checksum" "kubeseal.tar.gz"
tar xfz kubeseal.tar.gz
chmod +x kubeseal
mv ./kubeseal /usr/local/bin
rm -rf kubeseal.tar.gz

# Download & install yq
download_and_verify "https://github.com/mikefarah/yq/releases/download/v${yq_version}/yq_linux_amd64" "$yq_checksum" "yq"
chmod +x ./yq
mv ./yq /usr/local/bin

# terraform using Yum
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo && yum makecache fast
yum -y install terraform

# # ec2 instance selector
# download_and_verify "https://github.com/aws/amazon-ec2-instance-selector/releases/download/v${ec2_instance_selector_version}/ec2-instance-selector-linux-amd64" "$ec2_instance_selector_checksum" "ec2-instance-selector-linux-amd64"
# chmod +x ./ec2-instance-selector-linux-amd64
# mv ./ec2-instance-selector-linux-amd64 /usr/local/bin/ec2-instance-selector


# Download & install jq, envsubst (from GNU gettext utilities) and bash-completion
sudo yum -y install jq gettext bash-completion moreutils

# # Download & install yq for yaml processing
# echo 'yq() {
#   docker run --rm -i -v "${PWD}":/workdir mikefarah/yq "$@"
# }' | tee -a ~/.bashrc && source ~/.bashrc

# Verify the binaries are in the path and executable
for command in kubectl jq envsubst aws
  do
    which $command &>/dev/null && echo "$command in path" || echo "$command NOT FOUND"
  done

# # Download & install Session Manager plugin rpm package on Linux
# curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "session-manager-plugin.rpm"
# # Run the install command.
# sudo yum install -y session-manager-plugin.rpm

mkdir -p /eks-pentest-workshop

chown ec2-user /eks-pentest-workshop


# Install opencode server

#!/bin/bash

# Set HOME environment variable for root
export HOME=/root

# Install Docker
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo systemctl enable docker

# Create a code-server user
sudo useradd -m -s /bin/bash coder
sudo passwd -l coder
echo "coder ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/coder
sudo usermod -aG wheel coder

# Set up code-server using Docker
sudo mkdir -p /home/coder/project

# Run the code-server container in the background
sudo docker run -d \
  -p 80:8080 \
  -v "/home/coder/project:/home/coder/project" \
  -u "$(id -u coder):$(id -g coder)" \
  -e "DOCKER_USER=coder" \
  -e "PASSWORD=ReplaceWithYourStrongPassword" \
  bencdr/code-server-deploy-container:latest

# Print the public IP and access URL
PUBLIC_IP=$(curl -s ifconfig.me)
echo "code-server is running. Access it at: http://$PUBLIC_IP"
