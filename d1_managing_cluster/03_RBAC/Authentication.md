### Investigating Certificate based authentication

```shell
kubectl config view
kubectl config view --raw
```


### Read the certificate information out of our kubeconfig file

- Look for Subject: CN= is the username which is kubernetes-admin, it's also in the group (O=)system:masters

```shell
kubectl config view --raw -o jsonpath='{ .users[*].user.client-certificate-data }' | base64 --decode > admin.crt
openssl x509 -in admin.crt -text -noout | head
```

- We can use -v 6 to see the api request, and return code which is 200.

```shell
kubectl get pods -v 6
```

- Clean up files no longer needed

```shell
rm admin.crt
```

### Working with Service Accounts

- Getting Service Accounts information

```shell
kubectl get serviceaccounts
```

- A service account can contain image pull secrets and also mountable secrets, notice the mountable secrets name

```shell
kubectl describe serviceaccounts default
```

- Create a Service Accounts

```shell
kubectl create serviceaccount mysvcaccount1
```

- This new service account will get it's own secret.

```shell
kubectl describe serviceaccounts mysvcaccount1
```

- Create a workload, this uses the defined service account myserviceaccount

```shell
kubectl apply -f nginx-deployment.yaml
kubectl get pods 
```

- Get and store pod name to a shell variable

```shell
PODNAME=$(kubectl get pods -l app=nginx -o jsonpath='{ .items[*].metadata.name }')
kubectl get pod $PODNAME -o yaml
```

- Accessing the API Server inside a Pod

```shell
kubectl exec $PODNAME -it -- /bin/bash
ls /var/run/secrets/kubernetes.io/serviceaccount/
cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt 
cat /var/run/secrets/kubernetes.io/serviceaccount/namespace 
cat /var/run/secrets/kubernetes.io/serviceaccount/token 
```

- Load the token and cacert into variables for reuse

```shell
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
curl --cacert $CACERT -X GET https://kubernetes.default.svc/api/
curl --cacert $CACERT --header "Authorization: Bearer $TOKEN" -X GET https://kubernetes.default.svc/api/
```

- But it doesn't have any permissions to access objects

```shell
curl --cacert $CACERT --header "Authorization: Bearer $TOKEN" -X GET https://kubernetes.default.svc/api/v1/namespaces/default/pods
exit 
```

- We can also use impersonation to help with our authorization testing

```shell
kubectl auth can-i list pods --as=system:serviceaccount:default:mysvcaccount1
kubectl get pods -v 6 --as=system:serviceaccount:default:mysvcaccount1
```
