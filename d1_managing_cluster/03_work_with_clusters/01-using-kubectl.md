## Working with cluster

- Listing and inspecting your cluster...helpful for knowing which cluster is your current context

```
kubectl cluster-info

Kubernetes control plane is running at https://192.168.0.8:6443
CoreDNS is running at https://192.168.0.8:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

- Review status, roles and versions
```
kubectl get nodes

NAME    STATUS   ROLES           AGE     VERSION
node1   Ready    control-plane   68m     v1.27.2
node2   Ready    <none>          3m2s    v1.27.2
node3   Ready    <none>          2m59s   v1.27.2
node4   Ready    <none>          2m17s   v1.27.2
node5   Ready    <none>          2m13s   v1.27.2
```

- You can add an output modifier to get to *get* more information about a resource

```
kubectl get nodes -o wide

NAME    STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION      CONTAINER-RUNTIME
node1   Ready    control-plane   69m     v1.27.2   192.168.0.8   <none>        CentOS Linux 7 (Core)   4.4.0-210-generic   containerd://1.6.21
node2   Ready    <none>          3m34s   v1.27.2   192.168.0.7   <none>        CentOS Linux 7 (Core)   4.4.0-210-generic   containerd://1.6.21
node3   Ready    <none>          3m31s   v1.27.2   192.168.0.6   <none>        CentOS Linux 7 (Core)   4.4.0-210-generic   containerd://1.6.21
node4   Ready    <none>          2m49s   v1.27.2   192.168.0.5   <none>        CentOS Linux 7 (Core)   4.4.0-210-generic   containerd://1.6.21
node5   Ready    <none>          2m45s   v1.27.2   192.168.0.4   <none>        CentOS Linux 7 (Core)   4.4.0-210-generic   containerd://1.6.21
```

- Let's get a list of pods...but there isn't any running.

```
kubectl get pods 

No resources found in default namespace.
```

- True, but let's get a list of system pods. A namespace is a way to group resources together.
```
kubectl get pods --namespace kube-system

NAME                            READY   STATUS    RESTARTS   AGE
coredns-5d78c9869d-5qzkg        1/1     Running   0          70m
coredns-5d78c9869d-msbx2        1/1     Running   0          70m
etcd-node1                      1/1     Running   0          70m
kube-apiserver-node1            1/1     Running   0          70m
kube-controller-manager-node1   1/1     Running   0          70m
kube-proxy-9jvgc                1/1     Running   0          4m27s
kube-proxy-bwgtr                1/1     Running   0          4m30s
kube-proxy-g2rb4                1/1     Running   0          70m
kube-proxy-qhvr6                1/1     Running   0          3m45s
kube-proxy-rbxhz                1/1     Running   0          3m41s
kube-router-b847s               1/1     Running   0          3m41s
kube-router-ds2qf               1/1     Running   0          4m30s
kube-router-kh2gw               1/1     Running   0          48m
kube-router-rhgzd               1/1     Running   0          4m27s
kube-router-sr4xx               1/1     Running   0          3m45s
kube-scheduler-node1            1/1     Running   0          70m
```

- Let's get additional information about each pod. 
```
kubectl get pods --namespace kube-system -o wide
[node1 ~]$ kubectl get pods --namespace kube-system -owide
NAME                            READY   STATUS    RESTARTS   AGE     IP            NODE    NOMINATED NODE   READINESS GATES
coredns-5d78c9869d-5qzkg        1/1     Running   0          70m     10.5.0.2      node1   <none>           <none>
coredns-5d78c9869d-msbx2        1/1     Running   0          70m     10.5.0.3      node1   <none>           <none>
etcd-node1                      1/1     Running   0          70m     192.168.0.8   node1   <none>           <none>
kube-apiserver-node1            1/1     Running   0          70m     192.168.0.8   node1   <none>           <none>
kube-controller-manager-node1   1/1     Running   0          70m     192.168.0.8   node1   <none>           <none>
kube-proxy-9jvgc                1/1     Running   0          4m46s   192.168.0.6   node3   <none>           <none>
kube-proxy-bwgtr                1/1     Running   0          4m49s   192.168.0.7   node2   <none>           <none>
kube-proxy-g2rb4                1/1     Running   0          70m     192.168.0.8   node1   <none>           <none>
kube-proxy-qhvr6                1/1     Running   0          4m4s    192.168.0.5   node4   <none>           <none>
kube-proxy-rbxhz                1/1     Running   0          4m      192.168.0.4   node5   <none>           <none>
kube-router-b847s               1/1     Running   0          4m      192.168.0.4   node5   <none>           <none>
kube-router-ds2qf               1/1     Running   0          4m49s   192.168.0.7   node2   <none>           <none>
kube-router-kh2gw               1/1     Running   0          48m     192.168.0.8   node1   <none>           <none>
kube-router-rhgzd               1/1     Running   0          4m46s   192.168.0.6   node3   <none>           <none>
kube-router-sr4xx               1/1     Running   0          4m4s    192.168.0.5   node4   <none>           <none>
kube-scheduler-node1            1/1     Running   0          70m     192.168.0.8   node1   <none>           <none>
```

- Now let's get a list of everything that's running in all namespaces. In addition to pods, we see services, daemonsets, deployments and replicasets

```
kubectl get all --all-namespaces | more

NAMESPACE     NAME                                READY   STATUS    RESTARTS   AGE
kube-system   pod/coredns-5d78c9869d-5qzkg        1/1     Running   0          71m
kube-system   pod/coredns-5d78c9869d-msbx2        1/1     Running   0          71m
kube-system   pod/etcd-node1                      1/1     Running   0          71m
kube-system   pod/kube-apiserver-node1            1/1     Running   0          71m
kube-system   pod/kube-controller-manager-node1   1/1     Running   0          71m
kube-system   pod/kube-proxy-9jvgc                1/1     Running   0          5m36s
kube-system   pod/kube-proxy-bwgtr                1/1     Running   0          5m39s
kube-system   pod/kube-proxy-g2rb4                1/1     Running   0          71m
kube-system   pod/kube-proxy-qhvr6                1/1     Running   0          4m54s
kube-system   pod/kube-proxy-rbxhz                1/1     Running   0          4m50s
kube-system   pod/kube-router-b847s               1/1     Running   0          4m50s
kube-system   pod/kube-router-ds2qf               1/1     Running   0          5m39s
kube-system   pod/kube-router-kh2gw               1/1     Running   0          49m
kube-system   pod/kube-router-rhgzd               1/1     Running   0          5m36s
kube-system   pod/kube-router-sr4xx               1/1     Running   0          4m54s
kube-system   pod/kube-scheduler-node1            1/1     Running   0          71m

NAMESPACE     NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
default       service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP                  71m
kube-system   service/kube-dns     ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   71m

NAMESPACE     NAME                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-system   daemonset.apps/kube-proxy    5         5         5       5            5           kubernetes.io/os=linux   71m
kube-system   daemonset.apps/kube-router   5         5         5       5            5           <none>                   49m

NAMESPACE     NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
kube-system   deployment.apps/coredns   2/2     2            2           71m

NAMESPACE     NAME                                 DESIRED   CURRENT   READY   AGE
kube-system   replicaset.apps/coredns-5d78c9869d   2         2         2       71m
```

- Asking kubernetes for the resources it knows about. Let's look at the headers in each column. Name, Alias/shortnames, API Version 
is the resources in a namespace (namespaced resources), for example StorageClass isn't and is available to all namespaces and finally Kind...this is the object type.

```
kubectl api-resources | more

NAME                              SHORTNAMES   APIVERSION                             NAMESPACED   KIND
bindings                                       v1                                     true         Binding
componentstatuses                 cs           v1                                     false        ComponentStatus
configmaps                        cm           v1                                     true         ConfigMap
endpoints                         ep           v1                                     true         Endpoints
events                            ev           v1                                     true         Event
limitranges                       limits       v1                                     true         LimitRange
namespaces                        ns           v1                                     false        Namespace
nodes                             no           v1                                     false        Node
persistentvolumeclaims            pvc          v1                                     true         PersistentVolumeClaim
persistentvolumes                 pv           v1                                     false        PersistentVolume
pods                              po           v1                                     true         Pod
podtemplates                                   v1                                     true         PodTemplate
replicationcontrollers            rc           v1                                     true         ReplicationController
resourcequotas                    quota        v1                                     true         ResourceQuota
secrets                                        v1                                     true         Secret
serviceaccounts                   sa           v1                                     true         ServiceAccount
services                          svc          v1                                     true         Service
mutatingwebhookconfigurations                  admissionregistration.k8s.io/v1        false        MutatingWebhookConfiguration
validatingwebhookconfigurations                admissionregistration.k8s.io/v1        false        ValidatingWebhookConfiguration
customresourcedefinitions         crd,crds     apiextensions.k8s.io/v1                false        CustomResourceDefinition
apiservices                                    apiregistration.k8s.io/v1              false        APIService
controllerrevisions                            apps/v1                                true         ControllerRevision
daemonsets                        ds           apps/v1                                true         DaemonSet
deployments                       deploy       apps/v1                                true         Deployment
replicasets                       rs           apps/v1                                true         ReplicaSet
statefulsets                      sts          apps/v1                                true         StatefulSet
tokenreviews                                   authentication.k8s.io/v1               false        TokenReview
localsubjectaccessreviews                      authorization.k8s.io/v1                true         LocalSubjectAccessReview
selfsubjectaccessreviews                       authorization.k8s.io/v1                false        SelfSubjectAccessReview
selfsubjectrulesreviews                        authorization.k8s.io/v1                false        SelfSubjectRulesReview
subjectaccessreviews                           authorization.k8s.io/v1                false        SubjectAccessReview
horizontalpodautoscalers          hpa          autoscaling/v2                         true         HorizontalPodAutoscaler
cronjobs                          cj           batch/v1                               true         CronJob
jobs                                           batch/v1                               true         Job
certificatesigningrequests        csr          certificates.k8s.io/v1                 false        CertificateSigningRequest
leases                                         coordination.k8s.io/v1                 true         Lease
endpointslices                                 discovery.k8s.io/v1                    true         EndpointSlice
events                            ev           events.k8s.io/v1                       true         Event
flowschemas                                    flowcontrol.apiserver.k8s.io/v1beta3   false        FlowSchema
prioritylevelconfigurations                    flowcontrol.apiserver.k8s.io/v1beta3   false        PriorityLevelConfiguration
ingressclasses                                 networking.k8s.io/v1                   false        IngressClass
ingresses                         ing          networking.k8s.io/v1                   true         Ingress
networkpolicies                   netpol       networking.k8s.io/v1                   true         NetworkPolicy
runtimeclasses                                 node.k8s.io/v1                         false        RuntimeClass
poddisruptionbudgets              pdb          policy/v1                              true         PodDisruptionBudget
clusterrolebindings                            rbac.authorization.k8s.io/v1           false        ClusterRoleBinding
clusterroles                                   rbac.authorization.k8s.io/v1           false        ClusterRole
rolebindings                                   rbac.authorization.k8s.io/v1           true         RoleBinding
roles                                          rbac.authorization.k8s.io/v1           true         Role
priorityclasses                   pc           scheduling.k8s.io/v1                   false        PriorityClass
csidrivers                                     storage.k8s.io/v1                      false        CSIDriver
csinodes                                       storage.k8s.io/v1                      false        CSINode
csistoragecapacities                           storage.k8s.io/v1                      true         CSIStorageCapacity
storageclasses                    sc           storage.k8s.io/v1                      false        StorageClass
volumeattachments                              storage.k8s.io/v1                      false        VolumeAttachment
```

- You'll soon find your favorite alias
```
kubectl get no
```

- We can easily filter using group
```
kubectl api-resources | grep pod

pods                              po           v1                                     true         Pod
podtemplates                                   v1                                     true         PodTemplate
horizontalpodautoscalers          hpa          autoscaling/v2                         true         HorizontalPodAutoscaler
poddisruptionbudgets              pdb          policy/v1                              true         PodDisruptionBudget
```

- Explain an indivdual resource in detail
```
kubectl explain pod | more 
kubectl explain pod.spec | more 
kubectl explain pod.spec.containers | more 
kubectl explain pod --recursive | more 
```


- Let's take a closer look at our nodes using Describe. Check out Name, Taints, Conditions, Addresses, System Info, Non-Terminated Pods, and Events

```
kubectl describe nodes <cp_node> | more 

Name:               node1
Roles:              control-plane
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=node1
                    kubernetes.io/os=linux
                    node-role.kubernetes.io/control-plane=
                    node.kubernetes.io/exclude-from-external-load-balancers=
Annotations:        kubeadm.alpha.kubernetes.io/cri-socket: unix:///run/docker/containerd/containerd.sock
                    node.alpha.kubernetes.io/ttl: 0
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Fri, 11 Aug 2023 06:27:05 +0000
Taints:             node-role.kubernetes.io/control-plane:NoSchedule
Unschedulable:      false
....
```

```
kubectl describe nodes <node> | more

Name:               node2
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=node2
                    kubernetes.io/os=linux
Annotations:        kubeadm.alpha.kubernetes.io/cri-socket: /run/docker/containerd/containerd.sock
                    node.alpha.kubernetes.io/ttl: 0
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Fri, 11 Aug 2023 07:32:57 +0000
Taints:             <none>
Unschedulable:      false
...
```

- Use `-h` or `--help` to find help
```
kubectl -h | more
kubectl get -h | more
kubectl create -h | more
```

- Ok, so now that we're tired of typing commands out, let's enable 
bash auto-complete of our kubectl commands
```
sudo apt-get install -y bash-completion
echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc
kubectl g[tab][tab] po[tab][tab] --all[tab][tab]
```