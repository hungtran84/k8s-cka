# ConfigMap

## Creating ConfigMaps

- Create a PROD ConfigMap

```
kubectl create configmap appconfigprod --from-literal=DATABASE_SERVERNAME=sql.example.local --from-literal=BACKEND_SERVERNAME=be.example.local
configmap/appconfigprod created
```

- Create a QA ConfigMap. We can source our `ConfigMap` from files or from directories.
If no key, then the base name of the file.
Otherwise we can specify a key name to allow for more complex app configs and access to specific configuration elements.

```shell
# cat appconfigqa
DATABASE_SERVERNAME="sqlqa.example.local"
BACKEND_SERVERNAME="beqa.example.local"
```

```
kubectl create configmap appconfigqa --from-file=appconfigqa
configmap/appconfigqa created
```

- Each creation method provides a different structure in the `ConfigMap`

```
kubectl get configmap appconfigprod -o yaml
data:
  BACKEND_SERVERNAME: be.example.local
  DATABASE_SERVERNAME: sql.example.local
kind: ConfigMap
metadata:
  creationTimestamp: "2023-08-19T08:35:01Z"
  name: appconfigprod
  namespace: default
  resourceVersion: "4503013"
  uid: c1135354-692e-425f-9204-74b7f81b2abc

kubectl get configmap appconfigqa -o yaml
apiVersion: v1
data:
  appconfigqa: |
    DATABASE_SERVERNAME="sqlqa.example.local"
    BACKEND_SERVERNAME="beqa.example.local"
kind: ConfigMap
metadata:
  creationTimestamp: "2023-08-19T08:38:36Z"
  name: appconfigqa
  namespace: default
  resourceVersion: "4504696"
  uid: e3eed5d7-811d-4caa-ba2f-299a07c02627
```

## Using ConfigMaps in Pod Configurations

- First as environment variables

```
kubectl apply -f deployment-configmaps-env-prod.yaml
deployment.apps/hello-world-configmaps-env-prod created
```

- Let's see or configured enviroment variables

```shell
PODNAME=$(kubectl get pods | grep hello-world-configmaps-env-prod | awk '{print $1}' | head -n 1)
echo $PODNAME
hello-world-configmaps-env-prod-69c6848b5-rjsz8
```

```shell
kubectl exec -it $PODNAME -- env | sort
BACKEND_SERVERNAME=be.example.local
DATABASE_SERVERNAME=sql.example.local
HOME=/root
HOSTNAME=hello-world-configmaps-env-prod-566b854547-prw6f
KUBERNETES_PORT=tcp://10.32.0.1:443
KUBERNETES_PORT_443_TCP=tcp://10.32.0.1:443
KUBERNETES_PORT_443_TCP_ADDR=10.32.0.1
KUBERNETES_PORT_443_TCP_PORT=443
KUBERNETES_PORT_443_TCP_PROTO=tcp
KUBERNETES_SERVICE_HOST=10.32.0.1
KUBERNETES_SERVICE_PORT=443
KUBERNETES_SERVICE_PORT_HTTPS=443
NGINX_VERSION=1.25.2
NJS_VERSION=0.8.0
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
PKG_RELEASE=1~bookworm
TERM=xterm
```

- Second as files

```shell
kubectl apply -f deployment-configmaps-files-qa.yaml
deployment.apps/hello-world-configmaps-files-qa created
```

- Let's see our configmap exposed as a file using the key as the file name.

```shell
PODNAME=$(kubectl get pods | grep hello-world-configmaps-files-qa | awk '{print $1}' | head -n 1)
echo $PODNAME
```

```shell
kubectl exec -it $PODNAME -- cat /etc/appconfig/appconfigqa
DATABASE_SERVERNAME="sqlqa.example.local"
BACKEND_SERVERNAME="beqa.example.local"
```

- Our `ConfigMap` key, was the filename we read in, and the values are inside the file.
This is how we can read in whole files at a time and present them to the file system with the same name in one `ConfigMap`.
So think about using this for daemon configs like nginx, redis...etc.

```shell
kubectl get configmap appconfigqa -o yaml
```

- Updating a configmap, change BACKEND_SERVERNAME to beqa1.example.local

```yaml
kubectl edit configmap appconfigqa
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
data:
  appconfigqa: |
    DATABASE_SERVERNAME="sqlqa.example.local"
    BACKEND_SERVERNAME="beqa1.example.local"
kind: ConfigMap
metadata:
  creationTimestamp: "2023-08-19T08:38:36Z"
  name: appconfigqa
  namespace: default
  resourceVersion: "4504696"
  uid: e3eed5d7-811d-4caa-ba2f-299a07c02627
```

```shell
kubectl exec -it $PODNAME -- watch cat /etc/appconfig/appconfigqa
DATABASE_SERVERNAME="sqlqa.example.local"
BACKEND_SERVERNAME="beqa1.example.local"
```

- Cleaning up our resources

```shell
kubectl delete deployment hello-world-configmaps-env-prod
kubectl delete deployment hello-world-configmaps-files-qa
kubectl delete configmap appconfigprod
kubectl delete configmap appconfigqa
```

## Additional examples of using configmap in your Pods

- Reading from a directory, each file's basename will be a key in the `ConfigMap`, but you can define a key if needed

```
kubectl create configmap httpdconfigprod1 --from-file=./configs/
configmap/httpdconfigprod1 created
```

```shell
kubectl apply -f deployment-configmaps-directory-qa.yaml
PODNAME=$(kubectl get pods | grep hello-world-configmaps-directory-qa | awk '{print $1}' | head -n 1)
echo $PODNAME
```

```
kubectl exec -it $PODNAME -- /bin/sh

# ls /etc/httpd
httpd.conf  ssl.conf
# cat /etc/httpd/httpd.conf
A complex HTTPD configuration
# cat /etc/httpd/ssl.conf
All of our SSL configurations settings
# exit
```

- Defining a custom key for a file. All configuration will be under that key in the filesystem.

```shell
kubectl create configmap appconfigprod1 --from-file=app1=appconfigprod
configmap/appconfigprod1 created

kubectl describe configmap appconfigprod1
Name:         appconfigprod1
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
app1:
----
DATABASE_SERVERNAME="sql.example.local"
BACKEND_SERVERNAME="be.example.local"


BinaryData
====

Events:  <none>

kubectl apply -f deployment-configmaps-files-key-qa.yaml
deployment.apps/hello-world-configmaps-files-key-qa created

PODNAME=$(kubectl get pods | grep hello-world-configmaps-files-key-qa | awk '{print $1}' | head -n 1)
echo $PODNAME
hello-world-configmaps-files-key-qa-7c668cb8f8-l9zdz
```

```
kubectl exec -it $PODNAME -- /bin/sh 

# ls /etc/appconfig
app1
# ls /etc/appconfig/app1
/etc/appconfig/app1
# cat /etc/appconfig/app1
DATABASE_SERVERNAME="sql.example.local"
BACKEND_SERVERNAME="be.example.local"
# exit
```

- Cleanup time

```
kubectl delete deployments hello-world-configmaps-files-key-qa
kubectl delete deployments hello-world-configmaps-directory-qa
kubectl delete configmap httpdconfigprod1
```
