# ConfigMap

## Creating ConfigMaps

- Create a PROD ConfigMap

```yaml
kubectl create configmap appconfigprod --from-literal=DATABASE_SERVERNAME=sql.example.local --from-literal=BACKEND_SERVERNAME=be.example.local
```

- Create a QA ConfigMap
We can source our ConfigMap from files or from directories
If no key, then the base name of the file
Otherwise we can specify a key name to allow for more complex app configs and access to specific configuration elements more appconfigqa

```yaml
kubectl create configmap appconfigqa --from-file=appconfigqa
```

- Each creation method yeilded a different structure in the ConfigMap

```yaml
kubectl get configmap appconfigprod -o yaml
kubectl get configmap appconfigqa -o yaml
```

## Using ConfigMaps in Pod Configurations

- First as environment variables

```shell
kubectl apply -f deployment-configmaps-env-prod.yaml
```

- Let's see or configured enviroment variables

```shell
PODNAME=$(kubectl get pods | grep hello-world-configmaps-env-prod | awk '{print $1}' | head -n 1)
echo $PODNAME
```

```shell
kubectl exec -it $PODNAME -- printenv | sort
```

- Second as files

```shell
kubectl apply -f deployment-configmaps-files-qa.yaml
```

- Let's see our configmap exposed as a file using the key as the file name.

```shell
PODNAME=$(kubectl get pods | grep hello-world-configmaps-files-qa | awk '{print $1}' | head -n 1)
echo $PODNAME
```

```shell
kubectl exec -it $PODNAME -- /bin/sh 
ls /etc/appconfig
cat /etc/appconfig/appconfigqa
exit
```

- Our ConfigMap key, was the filename we read in, and the values are inside the file.
This is how we can read in whole files at a time and present them to the file system with the same name in one ConfigMap
So think about using this for daemon configs like nginx, redis...etc.

```shell
kubectl get configmap appconfigqa -o yaml
```

- Updating a configmap, change BACKEND_SERVERNAME to beqa1.example.local

```shell
kubectl edit configmap appconfigqa
```

```shell
kubectl exec -it $PODNAME -- watch cat /etc/appconfig/appconfigqa
```

- Cleaning up our demp

```shell
kubectl delete deployment hello-world-configmaps-env-prod
kubectl delete deployment hello-world-configmaps-files-qa
kubectl delete configmap appconfigprod
kubectl delete configmap appconfigqa
```

## Additional examples of using configmap in your Pods

- Reading from a directory, each file's basename will be a key in the ConfigMap...but you can define a key if needed

```shell
kubectl create configmap httpdconfigprod1 --from-file=./configs/
```

```shell
kubectl apply -f deployment-configmaps-directory-qa.yaml
PODNAME=$(kubectl get pods | grep hello-world-configmaps-directory-qa | awk '{print $1}' | head -n 1)
echo $PODNAME
```

```shell
kubectl exec -it $PODNAME -- /bin/sh 
ls /etc/httpd
cat /etc/httpd/httpd.conf
cat /etc/httpd/ssl.conf
exit
```

- Defining a custom key for a file. All configuration will be under that key in the filesystem.

```shell
kubectl create configmap appconfigprod1 --from-file=app1=appconfigprod
kubectl describe configmap appconfigprod1
kubectl apply -f deployment-configmaps-files-key-qa.yaml
PODNAME=$(kubectl get pods | grep hello-world-configmaps-files-key-qa | awk '{print $1}' | head -n 1)
echo $PODNAME
```

```shell
kubectl exec -it $PODNAME -- /bin/sh 
ls /etc/appconfig
ls /etc/appconfig/app1
cat /etc/appconfig/app1
exit
```

- Clean up after our demos

```shell
kubectl delete deployments hello-world-configmaps-files-key-qa
kubectl delete deployments hello-world-configmaps-directory-qa
kubectl delete configmap httpdconfigprod1
```
