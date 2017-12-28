#!/usr/bin/env bash

BLACK_ON_GREY=$'\e[47;30;1m'
NONE=$'\e[0m'

if [ $# -lt 2 ]
  then
    echo "Prerequisites:"
    echo "      - aws configure OR gcloud blah blah"
    echo "      - travis login --org"
    echo "      - docker login"
    echo ""
    echo "Usage:"
    echo "      provision-environment.sh <app-name> <slack-webhookurl>"
    echo ""
    echo "Add a new Slack Incomming webhook at :"
    echo ""
    echo "      https://slack.com/apps/manage/custom-integrations"
    echo ""
    exit 0
fi

APP_NAME=$1
SLACK_WEBHOOK_URL=$2

echo "${BLACK_ON_GREY}Provision state store${NONE}"
aws s3 mb s3://staticvoid-co-uk-state-store

export NAME=$APP_NAME.staticvoid.co.uk
export KOPS_STATE_STORE=s3://staticvoid-co-uk-state-store

echo "${BLACK_ON_GREY}Provision cluster${NONE}"
kops create cluster \
    --node-count 1 \
    --zones eu-west-2a \
    --master-zones eu-west-2a \
    --dns-zone staticvoid.co.uk \
    --node-size t2.micro \
    --master-size t2.micro \
    --topology private \
    --networking calico \
    --bastion \
    --cloud=aws \
    ${NAME}

kops update cluster ${NAME} --yes

isValidCluster=`kops validate cluster`
echo "${BLACK_ON_GREY}Waiting for cluster to be valid...${NONE}"
while [[ $isValidCluster != *"ready"* ]]
do
    echo "Please wait... still building."
    sleep 60
    isValidCluster=`kops validate cluster`
done
echo ".... cluster is READY"

echo "${BLACK_ON_GREY}Set kube context to created service${NONE}"
kubectl config use-context ${NAME}

echo "${BLACK_ON_GREY}Update cluster with AWS Route 53 additional policies for DNS extension${NONE}"
kops get cluster -o yaml > cluster-config.yaml
sed $'s/spec:/spec:\\\n  additionalPolicies:\\\n    node: |\\\n      [\\\n        {\\\n          "Effect": "Allow",\\\n          "Action": ["route53:*"],\\\n          "Resource": ["*"]\\\n        }\\\n      ]/g' cluster-config.yaml > cluster-config-with-route-53.yaml
kops replace -f cluster-config-with-route-53.yaml
kops update cluster ${NAME} --yes
kops rolling-update cluster
rm cluster-config*.yaml

echo "${BLACK_ON_GREY}Provision DNS extension${NONE}"
kubectl apply -f ./kube/external-dns.yaml

echo "${BLACK_ON_GREY}Provision Slack notifications${NONE}"
sed -e 's|SLACK_WEBHOOK_URL|'"${SLACK_WEBHOOK_URL}"'|g' ./kube/kube-slack.yaml > ./kube/${APP_NAME}-kube-slack.yaml
kubectl apply -f ./kube/${APP_NAME}-kube-slack.yaml

echo "${BLACK_ON_GREY}Provision dashboard${NONE}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

echo "${BLACK_ON_GREY}Export environment${NONE}"

mkdir -p ./env/

adminpwd=`kops get secrets kube -oplaintext`

echo "export NAME=${NAME}" > ./env/${APP_NAME}-env.sh
echo "export KOPS_STATE_STORE=${KOPS_STATE_STORE}" >> ./env/${APP_NAME}-env.sh
echo "export SLACK_HOOK=${SLACK_WEBHOOK_URL}" >> ./env/${APP_NAME}-env.sh
echo "kubectl config use-context ${NAME}" >> ./env/${APP_NAME}-env.sh

echo "To view the provisioned environment source the environment and goto kube dashboard ->"
echo ""
echo "source ./env/${APP_NAME}-env.sh"
echo "open http://api.${NAME}:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/"
echo ""
echo "NOTE : login with the admin password ${adminpwd}"
