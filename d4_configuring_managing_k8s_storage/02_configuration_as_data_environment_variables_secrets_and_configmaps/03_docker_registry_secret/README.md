## Pulling a Container from a Private Container Registry

- If needed we can specify this explicitly using the following parameters where:
DOCKERACC=<your docker username>
PASSWORD=<password of docker account>
EMAIL=<your registered email>

```
kubectl create secret docker-registry private-reg-cred \
    --docker-server=https://index.docker.io/v1/ \
    --docker-username=$DOCKERACC \
    --docker-password=$PASSWORD \
    --docker-email=$EMAIL
```

- Create a deployment using imagePullSecret in the Pod Spec.

```
kubectl apply -f deployment-private-registry.yaml
deployment.apps/hello-world-private-registry created
```

- Check out Containers and events section to ensure the container was actually pulled.
This is why I made sure they were deleted from each Node above. 

```
kubectl describe pods hello-world
```

- Cleanup time

```
kubectl delete -f deployment-private-registry.yaml
kubectl delete secret private-reg-cred
```