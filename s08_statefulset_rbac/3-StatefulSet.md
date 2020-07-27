## Create StatefulSet Basic

- Check StorageClass default

```
kubectl get storageclass
```

- Create a basic statefulset

```
kubectl apply -f Nginx_StatefulSet.yaml
```

- Check pods

```
kubectl get pods -l app=nginx
```

- Get Service

```
kubectl get service nginx
```

- Get Statefulset

```
kubectl get statefulset web
```

- Check using Stable Network Identities

```
for i in 0 1; do kubectl exec "web-$i" -- sh -c 'hostname'; done
```

- Using nslookup on the Pods' hostnames, you can examine their in-cluster DNS addresses:

```
kubectl run -i --tty --image busybox:1.28 dns-test --restart=Never --rm
nslookup web-0.nginx
```

- Delete pod and Wait for the StatefulSet to restart them. In one terminal, watch the StatefulSet's Pods, In a second terminal, use kubectl delete to delete all the Pods in the StatefulSet

```
kubectl get pod -w -l app=nginx
kubectl delete pod -l app=nginx
```

- Recheck hostname

```
for i in 0 1; do kubectl exec web-$i -- sh -c 'hostname'; done
```

- Rerun nslookup

```
kubectl run -i --tty --image busybox:1.28 dns-test --restart=Never --rm -- nslookup web-0.nginx
```

## Writing to Stable Storage

- Check PVC

```
kubectl get pvc -l app=nginx
```

- Write the Pods' hostnames to their index.html files and verify that the NGINX webservers serve the hostnames

```
kubectl exec "web-0" -- sh -c 'echo "Hello, $(hostname)" > /usr/share/nginx/html/index.html'
kubectl exec "web-1" -- sh -c 'echo "Hello, $(hostname)" > /usr/share/nginx/html/index.html'
```

```
kubectl exec -i -t "web-0" -- curl http://localhost/
```

- Delete pods and recheck value of file content

```
kubectl delete pod -l app=nginx
```

```
kubectl get pods -l app=nginx
```

```
kubectl exec -i -t "web-0" -- curl http://localhost/
```

## Scaling Up

- Increase replicas

```
kubectl scale sts web --replicas=5
```

- Get pods

```
kubectl get pods -w -l app=nginx
```

- Scale Down

```
kubectl scale sts web --replicas=3
```

- Get pods

```
kubectl get pods -w -l app=nginx
```

- Ordered Pod Termination. The controller deleted one Pod at a time, in reverse order with respect to its ordinal index, and it waited for each to be completely shutdown before deleting the next.

- Check PVC

```
kubectl get pvc -l app=nginx
```

- Clean up

```
kubectl delete -f Nginx_StatefulSet.yaml
kubectl delete pvc -l app=nginx
```

