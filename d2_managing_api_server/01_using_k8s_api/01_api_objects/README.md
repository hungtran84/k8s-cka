# API Objects

- Fetch the latest code from course repo
```
git clone https://github.com/hungtran84/k8s-cka.git 
cd k8s-cka/d2_managing_api_server/01_using_k8s_api/
```

- Get information about our current context, ensure we're logged into the correct cluster.
```
kubectl config get-contexts

CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
*         kubernetes-admin@kubernetes   kubernetes   kubernetes-admin 
```

- Change our context if needed.
```
kubectl config use-context kubernetes-admin@kubernetes
```


- Get a list of API Resources available in the cluster
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

- Using kubectl explain
```
kubectl explain pods | more
```

- Creating a pod with YAML
```
kubectl apply -f pod.yaml
```

- Let's look more closely at what we need in `pod.spec` and `pod.spec.containers`
```
kubectl explain pod.spec | more
kubectl explain pod.spec.containers | more
```

- Get a list of our currently running pods
```
kubectl get pod 
```

- Remove our pod
```
kubectl delete pod hello-world
```

- Working with kubectl dry-run.
Use kubectl dry-run for server side validatation of a manifest, the object will be sent to the API Server.
`dry-run=server` will tell you the object was created but it wasn't, 
it just goes through the whole process but didn't get stored in etcd.
```
kubectl apply -f deployment.yaml --dry-run=server
deployment.apps/hello-world created (server dry run)
```

- No deployment is created
```
kubectl get deployments
No resources found in default namespace.
```

- Use kubectl dry-run for client side validatation of a manifest
```
kubectl apply -f deployment.yaml --dry-run=client
deployment.apps/hello-world created (dry run)
```

- Let's do that one more time but with an error (`replica` should be `replicas`).
```
kubectl apply -f deployment-error.yaml --dry-run=server

Error from server (BadRequest): error when creating "deployment-error.yaml": Deployment in version "v1" cannot be handled as a Deployment: strict decoding error: unknown field "spec.replica"
```

- Use kubectl dry-run client to generate some yaml for an object
```
kubectl create deployment nginx --image=nginx --dry-run=client -oyaml | more
```
- Can be any object, let's try a pod
```
kubectl run pod nginx-pod --image=nginx --dry-run=client -o yaml | more
```

- We can combine that with IO redirection and store the YAML into a file
```
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deployment-generated.yaml
```

- And then we can deploy from that manifest or use it as a building block for more complex manfiests
```
kubectl apply -f deployment-generated.yaml
```

- Clean up from that demo, you can use delete with `-f` to delete all the resources in the manifests
```
kubectl delete -f deployment-generated.yaml
```

- Working with `kubectl diff`
Create a deployment with 4 replicas
```
kubectl apply -f deployment.yaml
deployment.apps/hello-world created
```


- Diff that with a deployment with 5 replicas and a new container image, you will see other metadata about the object output too.
```
kubectl diff -f deployment-new.yaml | more

iff -u -N /var/folders/5n/wybb_hvd521f6rt_k1m2y2zc0000gp/T/LIVE-3073281377/apps.v1.Deployment.default.hello-world /var/folders/5n/wybb_hvd521f6rt_k1m2y2zc0000gp/T/MERGED-1704172760/apps.v1.Deployment.default.hello-world
--- /var/folders/5n/wybb_hvd521f6rt_k1m2y2zc0000gp/T/LIVE-3073281377/apps.v1.Deployment.default.hello-world     2023-08-13 00:29:05
+++ /var/folders/5n/wybb_hvd521f6rt_k1m2y2zc0000gp/T/MERGED-1704172760/apps.v1.Deployment.default.hello-world   2023-08-13 00:29:05
@@ -6,7 +6,7 @@
     kubectl.kubernetes.io/last-applied-configuration: |
       {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"annotations":{},"labels":{"app":"hello-world"},"name":"hello-world","namespace":"default"},"spec":{"replicas":4,"selector":{"matchLabels":{"app":"hello-world"}},"template":{"metadata":{"labels":{"app":"hello-world"}},"spec":{"containers":[{"image":"ghcr.io/hungtran84/hello-app:1.0","name":"hello-world","ports":[{"containerPort":8080}]}]}}}}
   creationTimestamp: "2023-08-12T17:28:29Z"
-  generation: 1
+  generation: 2
   labels:
     app: hello-world
   name: hello-world
@@ -15,7 +15,7 @@
   uid: 51ded579-fc0d-498f-80e3-82b1cc21d087
 spec:
   progressDeadlineSeconds: 600
-  replicas: 4
+  replicas: 5
   revisionHistoryLimit: 10
   selector:
     matchLabels:
@@ -32,7 +32,7 @@
         app: hello-world
     spec:
       containers:
:...skipping...
diff -u -N /var/folders/5n/wybb_hvd521f6rt_k1m2y2zc0000gp/T/LIVE-3073281377/apps.v1.Deployment.default.hello-world /var/folders/5n/wybb_hvd521f6rt_k1m2y2zc0000gp/T/MERGED-1704172760/apps.v1.Deployment.default.hello-world
--- /var/folders/5n/wybb_hvd521f6rt_k1m2y2zc0000gp/T/LIVE-3073281377/apps.v1.Deployment.default.hello-world     2023-08-13 00:29:05
+++ /var/folders/5n/wybb_hvd521f6rt_k1m2y2zc0000gp/T/MERGED-1704172760/apps.v1.Deployment.default.hello-world   2023-08-13 00:29:05
@@ -6,7 +6,7 @@
     kubectl.kubernetes.io/last-applied-configuration: |
       {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"annotations":{},"labels":{"app":"hello-world"},"name":"hello-world","namespace":"default"},"spec":{"replicas":4,"selector":{"matchLabels":{"app":"hello-world"}},"template":{"metadata":{"labels":{"app":"hello-world"}},"spec":{"containers":[{"image":"ghcr.io/hungtran84/hello-app:1.0","name":"hello-world","ports":[{"containerPort":8080}]}]}}}}
   creationTimestamp: "2023-08-12T17:28:29Z"
-  generation: 1
+  generation: 2
   labels:
     app: hello-world
   name: hello-world
@@ -15,7 +15,7 @@
   uid: 51ded579-fc0d-498f-80e3-82b1cc21d087
 spec:
   progressDeadlineSeconds: 600
-  replicas: 4
+  replicas: 5
   revisionHistoryLimit: 10
   selector:
     matchLabels:
@@ -32,7 +32,7 @@
         app: hello-world
     spec:
       containers:
-      - image: ghcr.io/hungtran84/hello-app:1.0
+      - image: ghcr.io/hungtran84/hello-app:2.0
         imagePullPolicy: IfNotPresent
         name: hello-world
         ports:
```

- Clean up all the resources in the manifests
```
kubectl delete -f deployment.yaml
```