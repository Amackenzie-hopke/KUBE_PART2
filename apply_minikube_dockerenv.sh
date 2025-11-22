#!/usr/bin/env bash


# eval https://minikube.sigs.k8s.io/docs/handbook/pushing/#Linux
echo "we are now gonna force those builds into docker driver" || { echo "process failed"; exit 1;}
eval $(minikube docker-env)


echo "building docker images in node docker" || { echo "process failed"; exit 1;}
docker build -t backend:latest  ./DEV_OPS_KUBE/backend
docker build -t transactions:latest ./DEV_OPS_KUBE/transactions
docker build -t studentportfolio:latest ./DEV_OPS_KUBE/studentportfolio


echo "verifying images in nodes docker"
docker images  | grep -E  'backend|transactions|studentportfolio|nginx|mongo' || { echo "image verifcation failure"; exit 1;}


kubectl patch deployment/backend \
  --type='json' \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"IfNotPresent"}]'

kubectl patch deployment/transactions  \
  --type='json' \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"IfNotPresent"}]'

kubectl patch deployment/studentportfolio  \
  --type='json' \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"IfNotPresent"}]'

kubectl patch deployment/nginx  \
  --type='json' \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"IfNotPresent"}]'


echo "Applying Kubernetes manifests"
kubectl apply -f ./k8 || { echo "Manifest harder next time >:("; exit 1;}
kubectl rollout restart deployment.apps

kubectl get pods

minikube service nginx




