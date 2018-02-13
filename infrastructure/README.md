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

## Provisioning GKE env using K8s

* Add the following applications / CLI's  :
    - Docker
    - [Google Cloud SDK](https://cloud.google.com/kubernetes-engine/docs/quickstart)
    - [K8s Kubectl](https://cloud.google.com/kubernetes-engine/docs/quickstart)
    - Travis CLI
    
    (See details in ```install-clis.sh```)

* Ensure a default project has been set along with region e.g. ```gcloud config list``` results in something lke:
```
[compute]
zone = europe-west2-a
[core]
account = nathan.cashmore@gmail.com
disable_usage_reporting = True
project = iou-2018

Your active configuration is: [iou-2018]

```

'''''

* Provision environment using:
    ./provision-gke-environment.sh <project> <slack hook url>