#!/bin/bash

curl -sSL https://github.com/kubernetes/kops/releases/download/1.5.1/kops-darwin-amd64 -O
chmod +x kops-darwin-amd64
sudo mv kops-darwin-amd64 /usr/local/bin

curl -O https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin

sudo gem install travis -v 1.8.8 --no-rdoc --no-ri

brew update && brew install awscli

curl -O https://raw.githubusercontent.com/kubernetes/kops/master/hack/new-iam-user.sh


echo "Run the following to configure aws with id and secret"
echo ""
echo "aws configure"
echo ""
echo "Install docker from https://docs.docker.com/engine/installation/"
echo ""
echo "Use the following to create your k8s user with the right AWS permissions"
echo "sh new-iam-user.sh <group> <user>""
echo "aws iam list-users"
