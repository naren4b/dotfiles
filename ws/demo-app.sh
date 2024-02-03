kubectl --namespace default create deployment echoserver --image k8s.gcr.io/echoserver:1.10

kubectl wait --namespace default \
    --for=condition=ready pod \
    --selector=app=echoserver \
    --timeout=120s

kubectl --namespace default expose deployment echoserver --port=8080
kubectl --namespace default create ingress echoserver   --class=nginx   --rule="echoserver.127.0.0.1.nip.io/*=echoserver:8080,tls"

kubectl get ing 

curl -k https://echoserver.127.0.0.1.nip.io

echo "done"

