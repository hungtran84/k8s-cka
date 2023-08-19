## StorageClasses and Static Provisioning

- Check out our list of available storage classes, which one is default? Notice the `Provisioner`, `Parameters`, `Type` and `ReclaimPolicy`.

```
kubectl get StorageClass
NAME                     PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
premium-rwo              pd.csi.storage.gke.io   Delete          WaitForFirstConsumer   true                   6d15h
standard                 kubernetes.io/gce-pd    Delete          Immediate              true                   6d15h
standard-rwo (default)   pd.csi.storage.gke.io   Delete          WaitForFirstConsumer   true                   6d15h
```

- Let's take a closer look at `VolumeBindingMode`, `WaitForFirstConsumer` means the `PersistentVolume` will not be created until a Pod is scheduled to consume the volume.
```
kubectl describe StorageClass
Name:                  premium-rwo
IsDefaultClass:        No
Annotations:           components.gke.io/component-name=pdcsi,components.gke.io/component-version=0.16.11,components.gke.io/layer=addon
Provisioner:           pd.csi.storage.gke.io
Parameters:            type=pd-ssd
AllowVolumeExpansion:  True
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     WaitForFirstConsumer
Events:                <none>


Name:                  standard
IsDefaultClass:        No
Annotations:           components.gke.io/layer=addon,storageclass.kubernetes.io/is-default-class=false
Provisioner:           kubernetes.io/gce-pd
Parameters:            type=pd-standard
AllowVolumeExpansion:  True
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     Immediate
Events:                <none>


Name:                  standard-rwo
IsDefaultClass:        Yes
Annotations:           components.gke.io/layer=addon,storageclass.kubernetes.io/is-default-class=true
Provisioner:           pd.csi.storage.gke.io
Parameters:            type=pd-balanced
AllowVolumeExpansion:  True
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     WaitForFirstConsumer
Events:                <none>
```

- Check if any PV exists
```
kubectl get pv
No resources found
```

- Let's create a Deployment of an nginx pod with a ReadWriteOnce disk, 
we create a PVC and a Deployment that creates Pods that use that PVC

```
kubectl apply -f GCP-DeploymentDisk.yaml
persistentvolumeclaim/pvc-managed created
deployment.apps/nginx-gcp-deployment created
```

- Check out the `Access Mode`, `Reclaim Policy`, `Status`, `Claim` and `StorageClass`

```
kubectl get PersistentVolume
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS   REASON   AGE
pvc-f44711a2-d595-406e-bfef-202a11a55deb   10Gi       RWO            Delete           Bound    default/pvc-managed   premium-rwo             18s
```

- Check out the `Access Mode` on the `PersistentVolumeClaim`, status is `Bound` and it's `Volume` is the PV dynamically provisioned

```
kubectl get PersistentVolumeClaim
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-managed   Bound    pvc-f44711a2-d595-406e-bfef-202a11a55deb   10Gi       RWO            premium-rwo    2m4s
```

- Let's see if our single pod was created (the Status can take a second to transition to Running)

```
kubectl get pods
NAME                                    READY   STATUS    RESTARTS   AGE
nginx-gcp-deployment-6f89654cdc-rvhxw   1/1     Running   0          2m20s
```

- Clean up when we're finished

```
kubectl delete deployment nginx-gcp-deployment
kubectl delete PersistentVolumeClaim pvc-managed
```