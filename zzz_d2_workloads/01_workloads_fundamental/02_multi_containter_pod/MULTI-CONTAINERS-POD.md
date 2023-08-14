# Multi-containers pod

## Review multi-containers pod manifest

```shell
more multicontainer-pod.yaml
```

## Create our multi-container Pod

```shell
kubectl apply -f multicontainer-pod.yaml
```

## Connect to our Pod...not specifying a name defaults to the first container in the configuration

```shell
kubectl exec -it multicontainer-pod -- /bin/sh
ls -la /var/log
tail /var/log/index.html
exit
```

## Specify a container name and access the consumer container in our Pod

```shell
kubectl exec -it multicontainer-pod --container consumer -- /bin/sh
ls -la /usr/share/nginx/html
tail /usr/share/nginx/html/index.html
exit
```

## This application listens on port 80, we'll forward from 8080->80 or any port that available on your kubectl client

```shell
kubectl port-forward multicontainer-pod 8080:80 &
curl http://localhost:8080
```

## Kill our port-forward.

```shell
fg
ctrl+c
```

## Cleanup

```shell
kubectl delete pod multicontainer-pod
```