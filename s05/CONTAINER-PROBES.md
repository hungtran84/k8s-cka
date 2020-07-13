## Create pod with its liveness and readiness defined
kubectl apply -f container-probes.yaml

## The pod keeps restarting...
kubectl get pods --selector app=hello-world

## Let's figure out what's wrong
### 1. We can see in the events. The Liveness and Readiness probe failures.
### 2. Under Containers, Liveness and Readiness, we can see the current configuration. And the current probe configuration. Both are pointing to 8081.
### 3. Under Containers, Ready and Container Contidtions, we can see that the container isn't ready.
### 4. Our Container Port is 8080, that's what we want our probes, probings. 
kubectl describe pods

## Go ahead and change the probes to 8080
vi container-probes.yaml

## Apply change to the current deployment
kubectl apply -f container-probes.yaml

## Confirm our probes are pointing to the correct container port now, which is 8080.
 
## Let's check our status, a couple of things happened there.

### 1. Our Deployment ReplicaSet created a NEW Pod, when we pushed in the new deployment configuration.

### 2. It's not immediately ready because of our initialDelaySeconds which is 10 seconds.

### 3. If we wait long enough, the livenessProbe will kill the original Pod and it will go away.

### 4. Leaving us with the one pod in our Deployment's ReplicaSet

kubectl get pods 

kubectl delete deployment hello-world