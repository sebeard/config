if [ $# -lt 2 ]
  then
    echo "Prerequisites:"
    echo "      - aws configure OR gcloud blah blah"
    echo "      - travis login --org"
    echo "      - docker installed"
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

echo "Provision state store"
aws s3 mb s3://staticvoid-co-uk-state-store

export NAME=$APP_NAME.staticvoid.co.uk
export KOPS_STATE_STORE=s3://staticvoid-co-uk-state-store

echo "Provision cluster"
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
echo "Waiting for cluster to be valid..."
while [[ $isValidCluster != *"ready"* ]]
do
    echo "Please wait... still building."
    sleep 60
    isValidCluster=`kops validate cluster`
done
echo ".... cluster is READY"

echo "Set kube context to created service"
kubectl config use-context ${NAME}.staticvoid.co.uk

echo "Provision DNS extension"
kubectl apply -f ./kube/external-dns.yaml

echo "Provision Slack notifications"
sed -e 's|SLACK_WEBHOOK_URL|'"${SLACK_WEBHOOK_URL}"'|g' ./kube/kube-slack.yaml > ./kube/${APP_NAME}-kube-slack.yaml
kubectl apply -f ./kube/${APP_NAME}-kube-slack.yaml

echo "Provision dashboard"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
# kubectl convert -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard-head.yaml --output-version=rbac.authorization.k8s.io/v1alpha1 | kubectl apply -f -

echo "Provision docker"
docker login

echo "Provision Travis-CI"
export KUBE_CA_CERT=$(kubectl config view --flatten --output=json \
       | jq --raw-output '.clusters[0] .cluster ["certificate-authority-data"]')
export KUBE_ENDPOINT=$(kubectl config view --flatten --output=json \
       | jq --raw-output '.clusters[0] .cluster ["server"]')
export KUBE_ADMIN_CERT=$(kubectl config view --flatten --output=json \
       | jq --raw-output '.users[0] .user ["client-certificate-data"]')
export KUBE_ADMIN_KEY=$(kubectl config view --flatten --output=json \
       | jq --raw-output '.users[0] .user ["client-key-data"]')
export KUBE_USERNAME=$(kubectl config view --flatten --output=json \
       | jq --raw-output '.users[0] .user ["username"]')

travis env set KUBE_CA_CERT $KUBE_CA_CERT
travis env set KUBE_ENDPOINT $KUBE_ENDPOINT
travis env set KUBE_ADMIN_CERT $KUBE_ADMIN_CERT
travis env set KUBE_ADMIN_KEY $KUBE_ADMIN_KEY
travis env set KUBE_USERNAME $KUBE_USERNAME

echo "Export environment"

mkdir -p ./env/

echo "export NAME=${NAME}" > ./env/${APP_NAME}-env.sh
echo "export KOPS_STATE_STORE=${KOPS_STATE_STORE}" > ./env/${APP_NAME}-env.sh
echo "export SLACK_HOOK=${SLACK_WEBHOOK_URL}" > ./env/${APP_NAME}-env.sh
echo "kubectl config use-context ${NAME}" > ./env/${APP_NAME}-env.sh

echo "To view the provisioned environment source the environment and goto kube dashboard ->"
echo ""
echo "source ./env/${APP_NAME}-env.sh"
echo "kubectl proxy"
echo "http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/"
echo ""
echo "NOTE : login with the admin details obtained using"
echo "kubectl config view"
