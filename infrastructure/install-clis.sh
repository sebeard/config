curl -sSL https://github.com/kubernetes/kops/releases/download/1.5.1/kops-darwin-amd64 -O
chmod +x kops-darwin-amd64
sudo mv kops-darwin-amd64 /usr/local/bin

curl -O https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin

brew update && brew install awscli
aws configure

sudo gem install travis -v 1.8.8 --no-rdoc --no-ri
