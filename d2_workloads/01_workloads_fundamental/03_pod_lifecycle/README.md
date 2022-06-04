- Start up kubectl get events --watch and background it

```
kubectl get events --watch &
clear
```

- Create a pod from manifest

```
kubectl apply -f pod.yaml
```

- Access to pod and check the container process

```
kubectl exec -it hello-world-pod -- ps
ps
exit
```

- Kill the main process in container

```
kubectl exec -it hello-world-pod -- /usr/bin/killall hello-app
```


- Restart count increased by 1 after the container needed to be restarted.

```
kubectl get pods hello-world-pod
```

- Look at Containers->State, Last State, Reason, Exit Code, Restart Count and Events

```
kubectl describe pod hello-world-pod
```

- Cleanup time

```
kubectl delete pod hello-world-pod
```

- Create 2 pods with restartPolicy set as OnFailure/Never

```
kubectl apply -f pod-restart-policy.yaml
```

- Check to ensure both pods are up and running, we can see the restarts is 0

```
kubectl get pods 
```

- Kill main apps in pod with restartPolicy was set as Never and see how the container restart policy reacts

```
kubectl exec -it hello-world-never-pod -- /usr/bin/killall hello-app
kubectl get pods hello-world-never-pod
```

- Review container state, reason, exit code, ready and contitions Ready, ContainerReady

```
kubectl describe pod hello-world-never-pod
```

- Kill main apps in pod with restartPolicy was set as OnFailure and see how the container restart policy reacts

```
kubectl exec -it hello-world-onfailure-pod -- /usr/bin/killall hello-app
```

- We'll see 1 restart on the pod with the OnFailure restart policy.

```
kubectl get pods hello-world-onfailure-pod
```
