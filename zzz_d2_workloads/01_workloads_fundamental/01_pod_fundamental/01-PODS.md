- Start up kubectl get events --watch to monitor the cluster events in a separate terminal

```
kubectl get events --watch
```

- Create a pod...we can see the scheduling, container pulling and container starting.

```
kubectl apply -f hello-world-pod.yaml
```

- Start a Deployment with 1 replica. We see the deployment created, scaling the replica set and the replica set starting the first pod

```
kubectl apply -f deployment.yaml
```

- Scale a Deployment to 2 replicas. We see the scaling the replica set and the replica set starting the second pod

```
kubectl scale deployment hello-world --replicas=2
```

- We start off with the replica set scaling to 1, then  Pod deletion, then the Pod killing the container 

```
kubectl scale deployment hello-world --replicas=1
```

- Now, let's access our Pod's application directly, without a service and also off the Pod network.

```
kubectl port-forward PASTE_POD_NAME_HERE 80:8080
```

- Let's do it again, but this time with a non-priviledged port

```
kubectl port-forward PASTE_POD_NAME_HERE 8080:8080 &
```

- We can point curl to localhost, and kubectl port-forward will send the traffic through the API server to the Pod

```
curl http://localhost:8080
```

- Kill our port forward session.

```
fg
ctrl+c
```
