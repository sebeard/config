if [ $# -lt 2 ]
  then
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
    --node-count 3 \
    --zones eu-west-1a,eu-west-1b,eu-west-1c \
    --master-zones eu-west-1a,eu-west-1b,eu-west-1c \
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

echo "Provision DNS extension"
kubectl apply -f ./kube/external-dns.yaml

echo "Provision Slack notifications"
sed -e 's|SLACK_WEBHOOK_URL|'"${SLACK_WEBHOOK_URL}"'|g' ./kube/kube-slack.yaml > ./kube/${APP_NAME}-kube-slack.yaml
kubectl apply -f ./kube/${APP_NAME}-kube-slack.yaml

echo "Provision dashboard"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

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

echo "To view the provisioned environment go to ->"
echo ""
echo "https://api.$APP_NAME.staticvoid.co.uk/"
echo ""
echo ".. and login with the admin details obtained from 'kubectl config view'"
echo "Then goto the following ->"
echo ""
echo "https://api.$APP_NAME.staticvoid.co.uk/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/overview?namespace=default"
echo ""