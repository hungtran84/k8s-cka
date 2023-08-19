## NodePort

- Imperative, create a deployment with one replica

```
kubectl create deployment hello-world-nodeport --image=ghcr.io/hungtran84/hello-app:1.0
```

- If you don't define a type, the default is ClusterIP

```
kubectl expose deployment hello-world-nodeport --port=80 --target-port=8080 --type NodePort
```

- Get a list of services, examine the Type, CLUSTER-IP and NodePort...

```
kubectl get svc hello-world-nodeport
```


- Get the Service's ClusterIP, NodePort and Port and store that for reuse.

```
CLUSTERIP=$(kubectl get service hello-world-nodeport -o jsonpath='{ .spec.clusterIP }')
PORT=$(kubectl get service hello-world-nodeport -o jsonpath='{ .spec.ports[].port }')
NODEPORT=$(kubectl get service hello-world-nodeport -o jsonpath='{ .spec.ports[].nodePort }')
```

- Access the service inside the cluster

```
kubectl run bb -it --rm --image radial/busyboxplus:curl --restart Never -- curl http://$CLUSTERIP:$PORT
```


- And we can access the service by hitting the node port on ANY node in the cluster on the Node's Real IP or Name.

```
kubectl get nodes -o wide
curl http://<EXTERNAL-IP>:$NODEPORT
```