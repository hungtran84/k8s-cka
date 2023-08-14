## StorageClasses and Dynamic Provisioning

- Check out our list of available storage classes, which one is default? Notice the Provisioner, Parameters and ReclaimPolicy.

```
kubectl get StorageClass
kubectl describe StorageClass
```

let's create a Deployment of an nginx pod with a ReadWriteOnce disk, 
we create a PVC and a Deployment that creates Pods that use that PVC

```
kubectl apply -f GCPDeploymentDisk.yaml
```

- Check out the Access Mode, Reclaim Policy, Status, Claim and StorageClass

```
kubectl get PersistentVolume 
```

- Check out the Access Mode on the PersistentVolumeClaim, status is Bound and it's Volume is the PV dynamically provisioned

```
kubectl get PersistentVolumeClaim
```

- Let's see if our single pod was created (the Status can take a second to transition to Running)

```
kubectl get pods
```

- Clean up when we're finished

```
kubectl delete deployment nginx-gcp-deployment
kubectl delete PersistentVolumeClaim my-volume
```

