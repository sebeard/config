#!/bin/bash

brew update && brew install kops

brew install kubernetes-cli

sudo gem install travis -v 1.8.8 --no-rdoc --no-ri

brew update && brew install awscli

# https://cloud.google.com/sdk/
gcloud components install kubectl

curl -O https://raw.githubusercontent.com/kubernetes/kops/master/hack/new-iam-user.sh


echo "Run the following to configure aws with id and secret"
echo ""
echo "aws configure"
echo ""
echo "Install docker from https://docs.docker.com/engine/installation/"
echo ""
echo "Use the following to create your k8s user with the right AWS permissions"
echo "sh new-iam-user.sh <group> <user>"
echo "aws iam list-users"
