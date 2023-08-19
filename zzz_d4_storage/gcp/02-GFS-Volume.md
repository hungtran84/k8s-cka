## StorageClasses and Dynamic Provisioning

- Create Google File Storage

```bash
gcloud filestore instances create nfs-server \
    --project=lab-test-321409 \
    --zone=asia-southeast1-c \
    --tier=STANDARD \
    --file-share=name="vol1",capacity=1TB \
    --network=name="default"
```

- Get the IP Address of Google Filestore

```bash
gcloud filestore instances list
INSTANCE_NAME  ZONE               TIER      CAPACITY_GB  FILE_SHARE_NAME  IP_ADDRESS  STATE  CREATE_TIME
nfs-server     asia-southeast1-a  STANDARD  1024         vol1             10.98.1.90  READY  2021-09-18T04:31:33
```

- Create PV

```bash
kubectl apply -f GFS-Volume.yaml
```

- Create PVC

```bash
kubectl apply -f GFS-PersistantVolumeClaim.yaml
```

- Create a bare pod to mount the NFS-based volume

```bash
kubectl apply -f GFS-Pod.yaml
```

- Clean up k8s resource when we're finished

```bash
kubectl delete -f GFS-Pod.yaml
kubectl delete -f GFS-PersistantVolumeClaim.yaml
kubectl delete -f GFS-Volume.yaml
```

- Clean up GFS

```bash
gcloud filestore instances delete nfs-server --zone=asia-southeast1-a
```
