### Changing authorization for a service account

- The newly created serviceaccount didn't have access to the API Server to access Pods

```shell
kubectl auth can-i list pods --as=system:serviceaccount:default:mysvcaccount1
```

- But we can create an RBAC Role and bind that to our service account

```shell
kubectl create role demorole --verb=get,list --resource=pods
kubectl create rolebinding demorolebinding \ 
    --role=demorole 
    --serviceaccount=default:mysvcaccount1 
```

- Then the service account can access the API with the 

```shell
kubectl auth can-i list pods --as=system:serviceaccount:default:mysvcaccount1
kubectl get pods -v 6 --as=system:serviceaccount:default:mysvcaccount1
```

- Go back inside the pod again

```shell
kubectl get pods 
PODNAME=$(kubectl get pods -l app=nginx -o jsonpath='{ .items[*].metadata.name }')
kubectl exec $PODNAME -it -- /bin/bash

#Load the token and cacert into variables for reuse
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

curl --cacert $CACERT --header "Authorization: Bearer $TOKEN" -X GET https://kubernetes.default.svc/api/v1/namespaces/default/pods
exit 
```

- Clean up from this lab

```shell
kubectl delete deployment nginx
kubectl delete serviceaccount mysvcaccount1
kubectl delete role demorole 
kubectl delete rolebinding demorolebinding
```
