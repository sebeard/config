#!/usr/bin/env bash

BLACK_ON_GREY=$'\e[47;30;1m'
NONE=$'\e[0m'
FULL_BUILD=1

if [ $# -lt 1 ]
  then
    echo "Prerequisites:"
    echo "      - gcloud (With project, zone and dns configured)"
    echo "        * https://cloud.google.com/sdk/"		
    echo "        * https://cloud.google.com/kubernetes-engine/docs/quickstart"
    echo "        * https://cloud.google.com/dns/quickstart"
    echo "      - travis login --org"
    echo "      - docker login"
    echo ""
    echo "Usage:"
    echo "      provision-gke-environment.sh <cluster> [ <slack-webhookurl> <db-password> ]"
    echo ""
    echo "N.B. If only the <cluster> is specified this will be considered a re-run and the env will be sourced from the env dir"
    echo ""
    echo "Add a new Slack Incomming webhook at :"
    echo ""
    echo "      https://slack.com/apps/manage/custom-integrations"
    echo ""
    echo ""
    exit 0
fi

APP_NAME=$1

if [[ $# -ne 1 ]]
  then
    FULL_BUILD=0
    SLACK_WEBHOOK_URL=$2
    DB_NAME=${APP_NAME}-db
    DB_USERNAME=${APP_NAME}-user
    DB_PASSWORD=$3
  else
    source ./env/${APP_NAME}-env.sh
fi

PROJECT_NAME=$(gcloud config list --format="value(core.project)")

echo "${BLACK_ON_GREY}Running with the following gcloud configuration${NONE}"
gcloud config list

echo "${BLACK_ON_GREY}Create gcloud cluster${NONE}"
gcloud beta container clusters create ${APP_NAME} --image-type "UBUNTU" --machine-type "n1-standard-2"
gcloud container clusters get-credentials ${APP_NAME}

echo "${BLACK_ON_GREY}Provision DNS extension${NONE}"
kubectl apply -f ./kube/external-gcloud-dns.yaml

echo "${BLACK_ON_GREY}Provision Slack notifications${NONE}"
sed -e 's|SLACK_WEBHOOK_URL|'"${SLACK_WEBHOOK_URL}"'|g' ./kube/kube-slack.yaml > ./kube/${APP_NAME}-kube-slack.yaml
kubectl apply -f ./kube/${APP_NAME}-kube-slack.yaml

#echo "${BLACK_ON_GREY}Provision storage${NONE}"
#git clone https://github.com/openebs/openebs.git
#kubectl apply -f ./openebs/k8s/openebs-operator.yaml
#kubectl apply -f ./openebs/k8s/openebs-storageclasses.yaml
#
#echo "${BLACK_ON_GREY}Provision Crunchy Postgres DB${NONE}"
#./openebs/k8s/demo/crunchy-postgres/run.sh

echo "${BLACK_ON_GREY}Provision Postgres database${NONE}"
MYIP=$(dig +short myip.opendns.com @resolver1.opendns.com)

gcloud sql instances create ${APP_NAME} --database-version=POSTGRES_9_6 --region=europe-west2 --tier=db-f1-micro --authorized-networks=${MYIP}
gcloud sql databases create ${APP_NAME}-db --instance=${APP_NAME}
gcloud sql users create ${DB_USERNAME} '' --instance=${APP_NAME} --password=${DB_PASSWORD}

DB_HOSTNAME=$(gcloud sql instances describe iou --format="value(ipAddresses[0].ipAddress)")

echo "export APP_NAME=${APP_NAME}" > ./env/${APP_NAME}-env.sh
echo "export SLACK_HOOK=${SLACK_WEBHOOK_URL}" >> ./env/${APP_NAME}-env.sh
echo "export DB_HOSTNAME=${DB_HOSTNAME}" >> ./env/${APP_NAME}-env.sh
echo "export DB_NAME=${DB_NAME}" >> ./env/${APP_NAME}-env.sh
echo "export DB_USERNAME=${DB_USERNAME}" >> ./env/${APP_NAME}-env.sh
echo "export DB_PASSWORD=${DB_PASSWORD}" >> ./env/${APP_NAME}-env.sh
echo "gcloud container clusters get-credentials ${APP_NAME}" >> ./env/${APP_NAME}-env.sh

echo "View the cluster via the GCE Console at:"
echo "https://console.cloud.google.com/kubernetes/list?project=${PROJECT_NAME}"
echo ""
echo "When you want to execute commands against the cluster first:"
echo ""
echo "source $(pwd)/env/${APP_NAME}-env.sh"
echo ""
echo "If you want to blow away the cluster and associated DB:"
echo ""
echo "gcloud sql instances delete ${APP_NAME}"
echo "gcloud container clusters delete ${APP_NAME}"

