## Running a container as a specific user

- Running containers as a specific user: pod-as-user-guest.yaml

```
kubectl apply -f pod-as-user-guest.yaml
kubectl exec pod-as-user-guest id
```

- Clean

```
kubectl delete -f pod-as-user-guest.yaml
```

## Preventing a container from running as root

- Preventing containers from running as root: pod-run-as-non-root.yaml

```
kubectl apply -f pod-run-as-non-root.yaml
```

- If you deploy this pod, it gets scheduled, but is not allowed to run:

```
kubectl get po pod-run-as-non-root
```

- Clean

```
kubectl delete -f pod-run-as-non-root.yaml
```