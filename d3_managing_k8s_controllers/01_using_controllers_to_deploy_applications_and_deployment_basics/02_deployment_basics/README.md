## Creating a Deployment Imperatively 

- With `kubectl create`, we have lot's of options available  such as image, container ports, and replicas...
```
kubectl create deployment hello-world --image=ghcr.io/hungtran84/hello-app:1.0
deployment.apps/hello-world created

kubectl scale deployment hello-world --replicas=5
deployment.apps/hello-world scaled
```

- These two commands can be combined into one command if needed
```
kubectl create deployment hello-world1 --image=ghcr.io/hungtran84/hello-app:1.0 --replicas=5
deployment.apps/hello-world1 created
```

- Check out the status of our imperative deployment
```
kubectl get deployment 

NAME           READY   UP-TO-DATE   AVAILABLE   AGE
hello-world    5/5     5            5           2m22s
hello-world1   5/5     5            5           55s
```

- Cleanup time
```
kubectl delete deployment hello-world hello-world1
deployment.apps "hello-world" deleted
deployment.apps "hello-world1" deleted
```