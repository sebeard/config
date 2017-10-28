# Infrastructure

## Provisioning AWS env using K8s

* Add the following applications / CLI's :
    - Docker
    - Kops
    - AWS Cli
    - K8s Kubectl
    - Travis CLI

    (See details in ```install-clis.sh```)
* Create a user within AWS (not root ... someone else e.g. admin)
* Configure you AWS CLI to use that admin user with access key ID and secret

        aws configure

* Provision an environment using:

        ./provision-environment.sh <project> <slack hook url>

