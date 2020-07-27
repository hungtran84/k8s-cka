## Create User

## Create Service Account

- Each namespace has a default ServiceAccount, named default

```
kubectl get sa --all-namespaces | grep default
```

- Let’s inspect the ServiceAccount named default of the default namespace

```
kubectl get sa default -o yaml
```

- We can see here that a Secret is provided to this ServiceAccount. 

```
kubectl get secret default-token-dffkj -o yaml
```

- Decode base64

```
echo $(kubectl get secret default-token-grng7 --template={{.data.token}} | base64 --decode )
```

- Check how service account apply to a pod

```
kubectl apply -f pod-noserviceaccount.yaml
kubectl get po/pod-default -o yaml
```

- Important things to note here:
  * The serviceAccountName key is set with the name of the default ServiceAccount.
  * The information of the ServiceAccount is mounted inside the container of the Pod, through the usage of volume, in /var/run/secrets/kubernetes.io/serviceaccount

- Anonymous call of the API server

```
kubectl exec -ti pod-default -- sh
apk add --update curl
curl https://kubernetes/api --insecure
```

- Call using the ServiceAccount token

```
TOKEN=$(cat /run/secrets/kubernetes.io/serviceaccount/token)
curl -H "Authorization: Bearer $TOKEN" https://kubernetes/api/v1/ --insecure
```

- Let’s now try something more ambitious, and use this token to list all the Pods within the default namespace. The default ServiceAccount does not have enough rights to perform this query.

```
curl -H "Authorization: Bearer $TOKEN" https://kubernetes/api/v1/namespaces/default/pods/ --insecure
```

- Using a Custom ServiceAccount. Creation of a ServiceAccount

```
kubectl apply -f custom_serviceaccount.yaml
```

- Apply to pods

```
kubectl apply -f pod-with-sa.yaml
```

- Check again

```
kubectl exec -ti pod-demo-sa -- sh
apk add --update curl
TOKEN=$(cat /run/secrets/kubernetes.io/serviceaccount/token)
curl -H "Authorization: Bearer $TOKEN" https://kubernetes/api/v1/namespaces/default/pods/ --insecure
```

- Cleanup

```
kubectl delete -f pod-noserviceaccount.yaml
kubectl delete -f pod-with-sa.yaml
```

