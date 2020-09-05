# Discover Service

- Create a deployment with its clusterIP service

```
kubectl apply -f service-hello-world-clusterip.yaml
```


- Get the environment variables for the pod

```
PODNAME=$(kubectl get pods -o jsonpath='{ .items[].metadata.name }')
kubectl exec -it $PODNAME -- env | sort
```

Example output:

```
HELLO_WORLD_CLUSTERIP_PORT=tcp://10.0.14.193:80
HELLO_WORLD_CLUSTERIP_PORT_80_TCP=tcp://10.0.14.193:80
HELLO_WORLD_CLUSTERIP_PORT_80_TCP_ADDR=10.0.14.193
HELLO_WORLD_CLUSTERIP_PORT_80_TCP_PORT=80
HELLO_WORLD_CLUSTERIP_PORT_80_TCP_PROTO=tcp
HELLO_WORLD_CLUSTERIP_SERVICE_HOST=10.0.14.193
HELLO_WORLD_CLUSTERIP_SERVICE_PORT=80
HOME=/root
HOSTNAME=hello-world-clusterip-5c77dccc4-6bqmp
KUBERNETES_PORT=tcp://10.0.0.1:443
KUBERNETES_PORT_443_TCP=tcp://10.0.0.1:443
KUBERNETES_PORT_443_TCP_ADDR=10.0.0.1
KUBERNETES_PORT_443_TCP_PORT=443
```


- Create an externalName

```
kubectl apply -f service-externalname.yaml
```

```
kubectl get svc hello-world-api
```


- Verify the CNAME created at last step

```
kubectl run bb -it --rm --image busybox -- bin/sh
/ # nslookup hello-world-api.default.svc.cluster.local 10.116.0.10
```

Example output:
```
Server:         10.0.0.10
Address:        10.0.0.10:53hello-world-api

hello-world-api.default.svc.cluster.local       canonical name = hello-world.api.example.com
```