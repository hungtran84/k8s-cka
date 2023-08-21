## Creating and accessing Secrets

### Generic secret  
- Create a secret from a local file, directory or literal value.
They keys and values are case sensitive

```
kubectl create secret generic app1 --from-literal=USERNAME=app1login --from-literal=PASSWORD='S0methingS@Str0ng!'
secret/app1 created
```


- `Opaque` means it's an arbitrary user defined key/value pair. Data `2` means two key/value pairs in the secret.
Other types include service accounts and container registry authentication info

```
kubectl get secrets
NAME   TYPE     DATA   AGE
app1   Opaque   2      20s
```

- `app1` said it had 2 Data elements, let's look

```
kubectl describe secret app1
Name:         app1
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
PASSWORD:  18 bytes
USERNAME:  9 bytes
```

- If we need to access those at the command line.
These are wrapped in bash expansion to add a newline to output for readability

```
echo $(kubectl get secret app1 --template={{.data.USERNAME}} )
echo $(kubectl get secret app1 --template={{.data.USERNAME}} | base64 --decode )

echo $(kubectl get secret app1 --template={{.data.PASSWORD}} )
echo $(kubectl get secret app1 --template={{.data.PASSWORD}} | base64 --decode )
```



### Accessing Secrets inside a Pod

- As environment variables

```
kubectl apply -f deployment-secrets-env.yaml
deployment.apps/hello-world-secrets-env created
```

```
PODNAME=$(kubectl get pods | grep hello-world-secrets-env | awk '{print $1}' | head -n 1)

echo $PODNAME
hello-world-secrets-env-5758cdf59-5khsd
```

- Now let's get our enviroment variables from our container
Our Enviroment variables from our Pod Spec are defined

```
ubectl exec -it $PODNAME -- env | grep ^app1
app1username=app1login
app1password=S0methingS@Str0ng!
```

- Accessing Secrets as files

```
kubectl apply -f deployment-secrets-files.yaml
deployment.apps/hello-world-secrets-files created
```

- Grab our pod name into a variable

```
PODNAME=$(kubectl get pods | grep hello-world-secrets-files | awk '{print $1}' | head -n 1)
echo $PODNAME
```

- Looking more closely at the Pod we see volumes, `appconfig` and in `Mounts`.

```
kubectl describe pod $PODNAME

Name:             hello-world-secrets-files-7d895cbf7c-sxw72
Namespace:        default
Priority:         0
Service Account:  default
Node:             gke-gke-test-default-pool-03d0c6b2-sv8f/10.148.0.6
Start Time:       Sat, 19 Aug 2023 18:50:52 +0700
Labels:           app=hello-world-secrets-files
                  pod-template-hash=7d895cbf7c
Annotations:      <none>
Status:           Running
IP:               10.28.0.90
IPs:
  IP:           10.28.0.90
Controlled By:  ReplicaSet/hello-world-secrets-files-7d895cbf7c
Containers:
  hello-world:
    Container ID:   containerd://bf864fdcff1ef507965a12ca9d40355d6311fc6ac189058e2ff20e692c87977a
    Image:          ghcr.io/hungtran84/hello-app:1.0
    Image ID:       ghcr.io/hungtran84/hello-app@sha256:a3af38fd5a7dbfe9328f71b00d04516e8e9c778b4886e8aaac8d9e8862a09bc7
    Port:           8080/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Sat, 19 Aug 2023 18:50:53 +0700
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     100m
      memory:  128M
    Requests:
      cpu:        100m
      memory:     128M
    Environment:  <none>
    Mounts:
      /etc/appconfig from appconfig (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-bg67x (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  appconfig:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  app1
    Optional:    false
  kube-api-access-bg67x:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   Guaranteed
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  21s   default-scheduler  Successfully assigned default/hello-world-secrets-files-7d895cbf7c-sxw72 to gke-gke-test-default-pool-03d0c6b2-sv8f
  Normal  Pulled     20s   kubelet            Container image "ghcr.io/hungtran84/hello-app:1.0" already present on machine
  Normal  Created    20s   kubelet            Created container hello-world
  Normal  Started    20s   kubelet            Started container hello-world
```

- Let's access a shell on the Pod

```
kubectl exec -it $PODNAME -- /bin/sh
```

- Now we see the path we defined in the Volumes part of the Pod Spec
A directory for each KEY and it's contents are the value

```
ls /etc/appconfig
PASSWORD  USERNAME

cat /etc/appconfig/USERNAME
app1

cat /etc/appconfig/PASSWORD
S0methingS@Str0ng!

exit
```

- If you need to put only a subset of the keys in a secret check out this line here and look at items
https://kubernetes.io/docs/concepts/storage/volumes#secret


- Cleanup time!

```
kubectl delete secret app1
kubectl delete deployment hello-world-secrets-env
kubectl delete deployment hello-world-secrets-files
```


### Additional examples of using secrets in your Pods

- Create a secret using clear text and the stringData field

```
kubectl apply -f secret.string.yaml
secret/app2 created
```

- Create a secret with encoded values, preferred over clear text.

```
echo -n 'app2login' | base64
echo -n 'S0methingS@Str0ng!' | base64
kubectl apply -f secret.encoded.yaml
```

- Check out the list of secrets now available 

```
kubectl get secrets
NAME   TYPE     DATA   AGE
app2   Opaque   2      38s
app3   Opaque   2      8s
```

- There's also an `envFrom` example in here for you too

```
kubectl create secret generic app1 --from-literal=USERNAME=app1login --from-literal=PASSWORD='S0methingS@Str0ng!'
secret/app1 created
```

- Create the deployment, envFrom will create  enviroment variables for each key in the named secret app1 with and set it's value set to the secrets value

```
kubectl apply -f deployment-secrets-env-from.yaml
deployment.apps/hello-world-secrets-env-from created

PODNAME=$(kubectl get pods | grep hello-world-secrets-env-from | awk '{print $1}' | head -n 1)

kubectl exec -it $PODNAME -- printenv | sort
HOME=/root
HOSTNAME=hello-world-secrets-env-from-6cb76b9864-gsms9
KUBERNETES_PORT=tcp://10.32.0.1:443
KUBERNETES_PORT_443_TCP=tcp://10.32.0.1:443
KUBERNETES_PORT_443_TCP_ADDR=10.32.0.1
KUBERNETES_PORT_443_TCP_PORT=443
KUBERNETES_PORT_443_TCP_PROTO=tcp
KUBERNETES_SERVICE_HOST=10.32.0.1
KUBERNETES_SERVICE_PORT=443
KUBERNETES_SERVICE_PORT_HTTPS=443
PASSWORD=S0methingS@Str0ng!
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
TERM=xterm
USERNAME=app1login
```

- Clean up

```
kubectl delete secret app1
kubectl delete secret app2
kubectl delete secret app3
kubectl delete deployment hello-world-secrets-env-from
```
