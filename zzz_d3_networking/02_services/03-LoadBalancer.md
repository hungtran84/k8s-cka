# Load Balancer

- Imperative, create a deployment with one replica

```
kubectl create deployment hello-world-loadbalancer --image=ghcr.io/hungtran84/hello-app:1.0
```

- If you don't define a type, the default is ClusterIP

```
kubectl expose deployment hello-world-loadbalancer --port=80 --target-port=8080 --type LoadBalancer
```


- Get a list of services, examine the Type, CLUSTER-IP, NodePort, External IP

```
kubectl get svc hello-world-loadbalancer
```


- Access the application from Internet

```
LOADBALANCERIP=$(kubectl get service hello-world-loadbalancer -o jsonpath='{ .status.loadBalancer.ingress[].ip }')
curl http://$LOADBALANCERIP:$PORT
```
