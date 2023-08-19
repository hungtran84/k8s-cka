- Get a list of all the namespaces in our cluster
```
kubectl get namespaces

NAME              STATUS   AGE
default           Active   14h
gmp-public        Active   14h # GKE only
gmp-system        Active   14h # GKE only
kube-node-lease   Active   14h
kube-public       Active   14h
kube-system       Active   14h
```

- Get a list of all the API resources and if they can be in a namespace
```
kubectl api-resources --namespaced=true | head
NAME                           SHORTNAMES   APIVERSION                       NAMESPACED   KIND
bindings                                    v1                               true         Binding
configmaps                     cm           v1                               true         ConfigMap
endpoints                      ep           v1                               true         Endpoints
events                         ev           v1                               true         Event
limitranges                    limits       v1                               true         LimitRange
persistentvolumeclaims         pvc          v1                               true         PersistentVolumeClaim
pods                           po           v1                               true         Pod
podtemplates                                v1                               true         PodTemplate
replicationcontrollers         rc           v1                               true         ReplicationController

```

```
kubectl api-resources --namespaced=false | head

NAME                              SHORTNAMES   APIVERSION                             NAMESPACED   KIND
componentstatuses                 cs           v1                                     false        ComponentStatus
namespaces                        ns           v1                                     false        Namespace
nodes                             no           v1                                     false        Node
persistentvolumes                 pv           v1                                     false        PersistentVolume
mutatingwebhookconfigurations                  admissionregistration.k8s.io/v1        false        MutatingWebhookConfiguration
validatingwebhookconfigurations                admissionregistration.k8s.io/v1        false        ValidatingWebhookConfiguration
customresourcedefinitions         crd,crds     apiextensions.k8s.io/v1                false        CustomResourceDefinition
apiservices                                    apiregistration.k8s.io/v1              false        APIService
tokenreviews                                   authentication.k8s.io/v1               false        TokenReview
```

- Namespaces have state, Active and Terminating (when it's deleting)
```
kubectl describe namespaces

Name:         default
Labels:       kubernetes.io/metadata.name=default
Annotations:  <none>
Status:       Active

Resource Quotas
  Name:                              gke-resource-quotas
  Resource                           Used  Hard
  --------                           ---   ---
  count/ingresses.extensions         0     100
  count/ingresses.networking.k8s.io  0     100
  count/jobs.batch                   0     5k
  pods                               0     1500
  services                           1     500

No LimitRange resource.


Name:         gmp-public
Labels:       addonmanager.kubernetes.io/mode=Reconcile
              kubernetes.io/metadata.name=gmp-public
Annotations:  components.gke.io/layer: addon
Status:       Active

Resource Quotas
  Name:                              gke-resource-quotas
  Resource                           Used  Hard
  --------                           ---   ---
  count/ingresses.extensions         0     100
  count/ingresses.networking.k8s.io  0     100
  count/jobs.batch                   0     5k
  pods                               0     1500
  services                           0     500

No LimitRange resource.


Name:         gmp-system
Labels:       addonmanager.kubernetes.io/mode=Reconcile
              kubernetes.io/metadata.name=gmp-system
Annotations:  components.gke.io/layer: addon
Status:       Active

Resource Quotas
  Name:                              gke-resource-quotas
  Resource                           Used  Hard
  --------                           ---   ---
  count/ingresses.extensions         0     100
  count/ingresses.networking.k8s.io  0     100
  count/jobs.batch                   0     5k
  pods                               6     1500
  services                           2     500

No LimitRange resource.


Name:         kube-node-lease
Labels:       kubernetes.io/metadata.name=kube-node-lease
Annotations:  <none>
Status:       Active

Resource Quotas
  Name:                              gke-resource-quotas
  Resource                           Used  Hard
  --------                           ---   ---
  count/ingresses.extensions         0     100
  count/ingresses.networking.k8s.io  0     100
  count/jobs.batch                   0     5k
  pods                               0     1500
  services                           0     500

No LimitRange resource.


Name:         kube-public
Labels:       kubernetes.io/metadata.name=kube-public
Annotations:  <none>
Status:       Active

Resource Quotas
  Name:                              gke-resource-quotas
  Resource                           Used  Hard
  --------                           ---   ---
  count/ingresses.extensions         0     100
  count/ingresses.networking.k8s.io  0     100
  count/jobs.batch                   0     5k
  pods                               0     1500
  services                           0     500

No LimitRange resource.


Name:         kube-system
Labels:       kubernetes.io/metadata.name=kube-system
Annotations:  <none>
Status:       Active

Resource Quotas
  Name:                              gcp-critical-pods
  Resource                           Used  Hard
  --------                           ---   ---
  pods                               20    1G
  Name:                              gke-resource-quotas
  Resource                           Used  Hard
  --------                           ---   ---
  count/ingresses.extensions         0     100
  count/ingresses.networking.k8s.io  0     100
  count/jobs.batch                   0     5k
  pods                               22    1500
  services                           3     500

No LimitRange resource.
```
- Describe the details of an indivdual namespace
```
kubectl describe namespaces kube-system

Name:         kube-system
Labels:       kubernetes.io/metadata.name=kube-system
Annotations:  <none>
Status:       Active

Resource Quotas
  Name:                              gcp-critical-pods
  Resource                           Used  Hard
  --------                           ---   ---
  pods                               20    1G
  Name:                              gke-resource-quotas
  Resource                           Used  Hard
  --------                           ---   ---
  count/ingresses.extensions         0     100
  count/ingresses.networking.k8s.io  0     100
  count/jobs.batch                   0     5k
  pods                               22    1500
  services                           3     500

No LimitRange resource.
```
- Get all the pods in our cluster across all namespaces. Right now, only system pods, no user workload.
You can shorten `--all-namespaces` to `-A`
```
kubectl get pods --all-namespaces
```
- Get all the resource across all of our namespaces
```
kubectl get all --all-namespaces
```

- Get a list of the pods in the kube-system namespace
```
kubectl get pods --namespace kube-system
```
- Imperatively create a namespace
```
kubectl create namespace playground1
```

- Imperatively create a invalid namespace
```
kubectl create namespace Playground1

The Namespace "Playground1" is invalid: metadata.name: Invalid value: "Playground1": a lowercase RFC 1123 label must consist of lower case alphanumeric characters or '-', and must start and end with an alphanumeric character (e.g. 'my-name',  or '123-abc', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?')
```
| :boom: DANGER              |
|:---------------------------|
| namespace must be lower case and only dashes |

- Declaratively create a namespace
```
more namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: playgroundinyaml
```

```
kubectl apply -f namespace.yaml
namespace/playgroundinyaml created
```


- Start a deployment into our playground1 namespace
```
kubectl apply -f deployment.yaml
deployment.apps/hello-world created
```
- Create a resource imperatively
```
kubectl run hello-world-pod \
    --image=ghcr.io/hungtran84/hello-app:1.0 \
    --namespace playground1
``````

- List all the pods on our namespace
```
kubectl get pods -n playground1
```
- Get a list of all of the resources in our namespace: `Deployment`, `ReplicaSet` and `Pods`
```
kubectl get all --namespace=playground1

NAME                           READY   STATUS    RESTARTS   AGE
hello-world-6d59dfc665-5jpsz   1/1     Running   0          110s
hello-world-6d59dfc665-kx44c   1/1     Running   0          110s
hello-world-6d59dfc665-qxxz2   1/1     Running   0          110s
hello-world-6d59dfc665-whw9n   1/1     Running   0          110s
hello-world-pod                1/1     Running   0          44s
❯ kubectl get all --namespace=playground1
NAME                               READY   STATUS    RESTARTS   AGE
pod/hello-world-6d59dfc665-5jpsz   1/1     Running   0          2m36s
pod/hello-world-6d59dfc665-kx44c   1/1     Running   0          2m36s
pod/hello-world-6d59dfc665-qxxz2   1/1     Running   0          2m36s
pod/hello-world-6d59dfc665-whw9n   1/1     Running   0          2m36s
pod/hello-world-pod                1/1     Running   0          90s

NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/hello-world   4/4     4            4           2m39s

NAME                                     DESIRED   CURRENT   READY   AGE
replicaset.apps/hello-world-6d59dfc665   4         4         4       2m36s
```

- Try to delete all the pods in our namespace, this will delete the single pod.
But the pods under the Deployment controller will be recreated.
```
kubectl delete pods --all --namespace playground1
pod "hello-world-6d59dfc665-5jpsz" deleted
pod "hello-world-6d59dfc665-kx44c" deleted
pod "hello-world-6d59dfc665-qxxz2" deleted
pod "hello-world-6d59dfc665-whw9n" deleted
pod "hello-world-pod" deleted
```
- Get a list of all of the *new* pods in our namespace
```
kubectl get pods -n playground1

NAME                           READY   STATUS    RESTARTS   AGE
hello-world-6d59dfc665-2cf5m   1/1     Running   0          30s
hello-world-6d59dfc665-clphw   1/1     Running   0          30s
hello-world-6d59dfc665-cvwgc   1/1     Running   0          30s
hello-world-6d59dfc665-vk9vq   1/1     Running   0          30s
```
- Delete all of the resources in our namespace and the namespace and delete our other created namespace.
This deletes the Deployment controller, the Pods and ALL other resources in the namespaces
```
kubectl delete namespaces playground1
kubectl delete namespaces playgroundinyaml
```
- List all resources in all namespaces, now our Deployment is gone.
```
kubectl get all
kubectl get all --all-namespaces
```