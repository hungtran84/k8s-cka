## Create NFS storage in GCP

- Create a Google File Storage that can take up to 10 minutes

```
gcloud filestore instances create nfs-server \
    --zone=asia-southeast1-c \
    --tier=STANDARD \
    --file-share=name="vol1",capacity=1TB \
    --network=name="default"

API [file.googleapis.com] not enabled on project [red-grid-394709]. Would you like to enable and retry (this will take a few minutes)? (y/N)?  y

Enabling service [file.googleapis.com] on project [red-grid-394709]...
```

- Get the IP Address of Google Filestore

```bash
gcloud filestore instances list

INSTANCE_NAME: nfs-server
LOCATION: asia-southeast1-c
TIER: STANDARD
CAPACITY_GB: 1024
FILE_SHARE_NAME: vol1
IP_ADDRESS: 10.17.152.2
STATE: READY
CREATE_TIME: 2023-08-18T16:42:23
```

```
IP=$(gcloud filestore instances list | grep IP_ADDRESS | cut -d : -f 2)
```


## Static Provisioning Persistent Volumes
- Create a PV with the read/write many and retain as the reclaim policy
```
sed "s/1.2.3.4/$IP/g" GFS-PersistentVolume.yaml | kubectl apply -f-
persistentvolume/fileserver created
```

- Review the created resources, `Status`, `Access Mode` and `Reclaim Policy` is set to `Retain` rather than `Delete`. 
```
kubectl get PersistentVolume fileserver
NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
fileserver   1T         RWX            Retain           Available           gfs                     2m9s
```

- Look more closely at the PV and it's configuration
```
kubectl describe PersistentVolume fileserver
Name:            fileserver
Labels:          <none>
Annotations:     <none>
Finalizers:      [kubernetes.io/pv-protection]
StorageClass:    gfs
Status:          Available
Claim:           
Reclaim Policy:  Retain
Access Modes:    RWX
VolumeMode:      Filesystem
Capacity:        1T
Node Affinity:   <none>
Message:         
Source:
    Type:      NFS (an NFS mount that lasts the lifetime of a pod)
    Server:    10.17.152.2
    Path:      /vol1
    ReadOnly:  false
Events:        <none>
```



- Create a PVC on that PV
```
kubectl apply -f GFS-PersistentVolumeClaim.yaml
persistentvolumeclaim/fileserver-claim created
```

- Check the status, now it's `Bound` due to the PVC on the PV.
```
kubectl get PersistentVolume
NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                      STORAGECLASS   REASON   AGE
fileserver   1T         RWX            Retain           Bound    default/fileserver-claim   gfs                     6m59s
```

- We defined the PVC, it statically provisioned the PV...but it's not mounted yet.
```
kubectl get PersistentVolumeClaim fileserver-claim
NAME               STATUS   VOLUME       CAPACITY   ACCESS MODES   STORAGECLASS   AGE
fileserver-claim   Bound    fileserver   1T         RWX            gfs            2m42s
```
```
kubectl describe PersistentVolumeClaim fileserver-claim
Name:          fileserver-claim
Namespace:     default
StorageClass:  gfs
Status:        Bound
Volume:        fileserver
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      1T
Access Modes:  RWX
VolumeMode:    Filesystem
Used By:       <none>
Events:        <none>
```

- Let create 2 bare pods that mount the NFS volume
```
kubectl apply -f GFS-Pods.yaml
pod/my-pod1 created
pod/my-pod2 created
```

- Access to `my-pod1` to create/upload file to NFS storage
```
kubectl exec -it my-pod1 -- /bin/bash
root@my-pod1:/# echo "Hello students" > workdir/test.txt
root@my-pod1:/# exit
exit
```

- Delete `my-pod1`
```
kubectl delete pod my-pod1
```
- Check if `my-pod2` can access the same data
```
kubectl exec -it my-pod2 -- cat workdir/test.txt
Hello students
```

- Create a simple html in NFS storage using the existing bare pod
```
kubectl exec -it my-pod2 -- /bin/bash
root@my-pod2:/# echo "Hello from our NFS mount" > workdir/demo.html
root@my-pod2:/# exit
```

- Let's create a Pod (in a Deployment and add a Service) with a PVC on `fileserver-claim`
```
kubectl apply -f nfs.nginx.yaml
deployment.apps/nginx-nfs-deployment created
service/nginx-nfs-service created

kubectl get service nginx-nfs-service
NAME                TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes          ClusterIP   10.32.0.1    <none>        443/TCP   6d1h
nginx-nfs-service   ClusterIP   10.32.2.81   <none>        80/TCP    27s
```

- Keep using `my-pod2` to test the website
```
kubectl exec -it my-pod2 -- curl http://nginx-nfs-service/web-app/demo.html
Hello from our NFS mount
```

## Controlling PV access with Access Modes and persistentVolumeReclaimPolicy
- Scale up the deployment to 4 replicas
kubectl scale deployment nginx-nfs-deployment --replicas=4
deployment.apps/nginx-nfs-deployment scaled

- Now let's look at who's attached to the pvc, all 5 Pods (including `my-pod2`).
Our `AccessMode` for this PV and PVC is `RWX` `ReadWriteMany`

```
kubectl describe PersistentVolumeClaim

Name:          fileserver-claim
Namespace:     default
StorageClass:  gfs
Status:        Bound
Volume:        fileserver
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      1T
Access Modes:  RWX
VolumeMode:    Filesystem
Used By:       my-pod2
               nginx-nfs-deployment-5d7864dcc8-67xzw
               nginx-nfs-deployment-5d7864dcc8-c6rbr
               nginx-nfs-deployment-5d7864dcc8-vffz7
               nginx-nfs-deployment-5d7864dcc8-wqhjq
Events:        <none>
```

- Now when we access our application we're getting load balanced across all the pods hitting the same PV data.

- Let's delete our deployment and bare pod
```
kubectl delete deployment nginx-nfs-deployment
deployment.apps "nginx-nfs-deployment" deleted
```

```
kubectl delete pod my-pod2
pod "my-pod2" deleted
```

- Check status, still bound on the PV
```
kubectl get PersistentVolume 
NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                      STORAGECLASS   REASON   AGE
fileserver   1T         RWX            Retain           Bound    default/fileserver-claim   gfs                     43m
```

- Because the PVC still exists...
```
kubectl get PersistentVolumeClaim

NAME               STATUS   VOLUME       CAPACITY   ACCESS MODES   STORAGECLASS   AGE
fileserver-claim   Bound    fileserver   1T         RWX            gfs            37m
```

- We can re-use the same PVC and PV from a Pod definition beecause we didn't delete the PVC.
```
kubectl apply -f nfs.nginx.yaml
```

- Our app is up and running
```
kubectl get pods 
NAME                                    READY   STATUS    RESTARTS   AGE
nginx-nfs-deployment-5d7864dcc8-69wzm   1/1     Running   0          20s
```

- Delete the deployment again ...
```
kubectl delete deployment nginx-nfs-deployment
```

- AND delete the PersistentVolumeClaim
```
kubectl delete PersistentVolumeClaim fileserver-claim
persistentvolumeclaim "fileserver-claim" deleted
```


- PV status is now Released which means no one can claim this PV
```
kubectl get PersistentVolume

NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM                      STORAGECLASS   REASON   AGE
fileserver   1T         RWX            Retain           Released   default/fileserver-claim   gfs                     48m
```

- Let's try to use it and see what happend, recreate the PVC for this PV
```
kubectl apply -f GFS-PersistentVolumeClaim.yaml
persistentvolumeclaim/fileserver-claim created
```

- Then try to use the PVC/PV in a Pod definition
```
kubectl apply -f nfs.nginx.yaml
deployment.apps/nginx-nfs-deployment created
service/nginx-nfs-service unchanged
```

- Pod creation is Pending
```
kubectl get pods
NAME                                    READY   STATUS    RESTARTS   AGE
nginx-nfs-deployment-5d7864dcc8-v2xgn   0/1     Pending   0          25s
```

- As is PVC Status `Pending` because that PV is `Released` and our `Reclaim Policy` is `Retain`
```
kubectl get PersistentVolumeClaim
NAME               STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
fileserver-claim   Pending                                      gfs            2m6s

kubectl get PersistentVolume
NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM                      STORAGECLASS   REASON   AGE
fileserver   1T         RWX            Retain           Released   default/fileserver-claim   gfs                     52m
```

- Time to clean up for the next demo
```
kubectl delete -f nfs.nginx.yaml
kubectl delete pvc fileserver-claim 
kubectl delete pv fileserver
```

- Don't forget to delete pricy GCP FileStore
```
gcloud filestore instances delete nfs-server --zone=asia-southeast1-c

You are about to delete Filestore instance projects/red-grid-394709/locations/asia-southeast1-c/instances/nfs-server.
Are you sure?

Do you want to continue (Y/n)?  y

Waiting for [operation-1692439459324-60343c4c6e277-c465553a-96662aea] to finish...working  
```
