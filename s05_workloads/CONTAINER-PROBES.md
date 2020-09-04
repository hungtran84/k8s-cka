- Create pod with its liveness and readiness defined

```
kubectl apply -f container-probes.yaml
```

- The pod keeps restarting...
kubectl get pods --selector app=hello-world

- Let's figure out what's wrong

* We can see in the events. The Liveness and Readiness probe failures.
* Under Containers, Liveness and Readiness, we can see the current configuration. And the current probe configuration. Both are pointing to 8081.
* Under Containers, Ready and Container Contidtions, we can see that the container isn't ready.
* Our Container Port is 8080, that's what we want our probes, probings. 

```
kubectl describe pods
```

- Go ahead and change the probes to 8080

```
vi container-probes.yaml
```

- Apply change to the current deployment

```
kubectl apply -f container-probes.yaml
```

Confirm our probes are pointing to the correct container port now, which is 8080.
 
- Let's check our status, a couple of things happened there.

* Our Deployment ReplicaSet created a NEW Pod, when we pushed in the new deployment configuration.

* It's not immediately ready because of our initialDelaySeconds which is 10 seconds.

* If we wait long enough, the livenessProbe will kill the original Pod and it will go away.

* Leaving us with the one pod in our Deployment's ReplicaSet

```
kubectl get pods 
```

```
kubectl delete deployment hello-world
```