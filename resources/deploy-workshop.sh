
# populate interpolated variables
source .env
envsubst < workshop/modules.in.yaml > workshop/modules.yaml
envsubst < other/resources/postgres/overrides.in.yaml > other/resources/postgres/overrides.yaml
envsubst < other/resources/greenplum/overrides.in.yaml > other/resources/greenplum/overrides.yaml
envsubst < other/resources/greenplum/minio-site.in.xml > other/resources/greenplum/minio-site.xml

# pre-initialize required services
resources/setup.sh

# rebuild workshop image
DATA_E2E_WORKSHOP_IMAGE_VERSION=`date "+%Y%m%d.%H%M"`
echo "Building version...$DATA_E2E_WORKSHOP_IMAGE_VERSION"
echo $DATA_E2E_REGISTRY_PASSWORD | docker login --username=oawofolu --password-stdin
tar -xzvf other/resources/helm*.tar.gz -C other/resources && \
    chmod +x other/resources/linux-amd64/helm && \
    tar -zvxf other/resources/k9s*.tar.gz -C other/resources && \
    chmod +x other/resources/k9s && \
    mv other/resources/k9s other/resources/bin/k9s &&
    mv other/resources/linux-amd64/helm other/resources/bin/helm &&
    chmod +x workshop/terminal/*.sh

docker build -t $DATA_E2E_REGISTRY_URL:$DATA_E2E_WORKSHOP_IMAGE_VERSION .
docker tag $DATA_E2E_REGISTRY_URL:$DATA_E2E_WORKSHOP_IMAGE_VERSION $DATA_E2E_REGISTRY_URL
docker push $DATA_E2E_REGISTRY_URL:$DATA_E2E_WORKSHOP_IMAGE_VERSION
docker push $DATA_E2E_REGISTRY_URL
#  create imagePullSecret
kubectl create secret docker-registry eduk8s-demo-creds --docker-username=$DATA_E2E_REGISTRY_USERNAME --docker-password=$DATA_E2E_REGISTRY_PASSWORD --docker-email=$DATA_E2E_REGISTRY_EMAIL -n eduk8s || true
# redeploy workshop
kubectl delete --all eduk8s-training; kubectl apply -k .; watch kubectl get eduk8s-training