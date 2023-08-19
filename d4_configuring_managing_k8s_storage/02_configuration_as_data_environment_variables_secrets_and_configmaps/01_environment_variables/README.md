## Passing Configuration into Containers using Environment Variables
- Create two deployments, one for a database system and the other our application.
```
kubectl apply -f deployment-alpha.yaml
deployment.apps/hello-world-alpha created
service/hello-world-alpha created

kubectl apply -f deployment-beta.yaml
deployment.apps/hello-world-beta created
service/hello-world-beta created
```

- Let's look at the services
```
kubectl get service
NAME                TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
hello-world-alpha   ClusterIP   10.32.12.208   <none>        80/TCP    85s
hello-world-beta    ClusterIP   10.32.10.122   <none>        80/TCP    60s
kubernetes          ClusterIP   10.32.0.1      <none>        443/TCP   6d16h
```

- Now let's get the name of one of our pods

```
PODNAME=$(kubectl get pods | grep hello-world-alpha | awk '{print $1}' | head -n 1)
echo $PODNAME
```

- Inside the Pod, let's read the enviroment variables from our container
Notice the alpha information is there but not the beta information. Since beta wasn't defined when the Pod started.

```
kubectl exec -it $PODNAME -- /bin/sh 
printenv | sort
exit
```

- If you delete the pod and it gets recreated, you will get the variables for the alpha and beta service information.

```
kubectl delete pod $PODNAME
```

- Get the new pod name and check the environment variables...the variables are define at Pod/Container startup.

```
PODNAME=$(kubectl get pods | grep hello-world-alpha | awk '{print $1}' | head -n 1)
kubectl exec -it $PODNAME -- /bin/sh -c "printenv | sort"
```

- If we delete our serivce and deployment 

```
kubectl delete deployment hello-world-beta
kubectl delete service hello-world-beta
```

- The enviroment variables stick around...to get a new set, the pod needs to be recreated.

```
kubectl exec -it $PODNAME -- /bin/sh -c "printenv | sort"
```


- Let's clean up after our demo

```
kubectl delete -f deployment-alpha.yaml
```s