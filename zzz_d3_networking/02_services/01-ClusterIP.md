# ClusterIP

- Imperative, create a deployment with one replica

```
kubectl create deployment hello-world-clusterip --image=ghcr.io/hungtran84/hello-app:1.0
```

- If you don't define a type, the default is ClusterIP

```
kubectl expose deployment hello-world-clusterip --port=80 --target-port=8080 --type ClusterIP
```

- Get a list of services, examine the Type, CLUSTER-IP and Port

```
kubectl get svc
```

- Get the Service's ClusterIP and store that for reuse.

```
SERVICEIP=$(kubectl get service hello-world-clusterip -o jsonpath='{ .spec.clusterIP }')
echo $SERVICEIP
```

- Access the service inside the cluster

```
kubectl run bb -it --rm --image radial/busyboxplus:curl --restart Never -- curl http://$SERVICEIP
```

Or using service name. Fullname should be: <service-name>.<namepsace>

```
kubectl run bb -it --rm --image radial/busyboxplus:curl --restart Never -- curl http://hello-world-clusterip
```

- Get a list of the endpoints for a service.

```
kubectl get endpoints hello-world-clusterip
```

- Scale the deployment, new endpoints are registered automatically

```
kubectl scale deployment hello-world-clusterip --replicas=6
```

```
kubectl get endpoints hello-world-clusterip
```
