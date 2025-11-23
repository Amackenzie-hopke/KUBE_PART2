#!/usr/bin/env bash


# eval https://minikube.sigs.k8s.io/docs/handbook/pushing/#Linux
echo "we are now gonna force those builds into docker driver" 
eval $(minikube docker-env) || { echo "process failed"; exit 1;}


echo "building docker images in node docker"
docker build -t backend  ./DEV_OPS_KUBE/backend || { echo "process failed"; exit 1;}
docker build -t transactions ./DEV_OPS_KUBE/transactions || { echo "process failed"; exit 1;}
docker build -t studentportfolio ./DEV_OPS_KUBE/studentportfolio || { echo "process failed"; exit 1;}


echo "verifying images in nodes docker"
docker images  | grep -E  'backend|transactions|studentportfolio|nginx|mongo' || { echo "image verifcation failure"; exit 1;}


echo "Applying Kubernetes manifests"
kubectl apply -f ./k8 || { echo "Manifest harder next time >:("; exit 1;}
kubectl rollout restart deployment.apps

kubectl get pods

minikube service nginx




