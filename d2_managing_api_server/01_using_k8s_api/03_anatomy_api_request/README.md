## Anatomy of an API Request
- Creating a pod with YAML
```
kubectl apply -f pod.yaml
pod/hello-world created
```
- Get a list of our currently running Pods
```
kubectl get pod hello-world

NAME          READY   STATUS    RESTARTS   AGE
hello-world   1/1     Running   0          27s
```

- We can use the `-v` option to increase the verbosity of our request.
Display requested resource URL. Focus on `VERB`, `API Path` and `Response` code
```
kubectl get pod hello-world -v 6 

I0813 00:42:18.690429   11888 loader.go:373] Config loaded from file:  /Users/hungts/.kube/config
I0813 00:42:18.715342   11888 round_trippers.go:553] GET https://127.0.0.1:6443/api/v1/namespaces/default/pods/hello-world 200 OK in 16 milliseconds
NAME          READY   STATUS    RESTARTS   AGE
hello-world   1/1     Running   0          91s
```
- Same output as 6, add HTTP Request Headers. Focus on application type, and User-Agent
```
kubectl get pod hello-world -v 7 

I0813 00:43:11.785576   12349 loader.go:373] Config loaded from file:  /Users/hungts/.kube/config
I0813 00:43:11.795406   12349 round_trippers.go:463] GET https://127.0.0.1:6443/api/v1/namespaces/default/pods/hello-world
I0813 00:43:11.795426   12349 round_trippers.go:469] Request Headers:
I0813 00:43:11.795432   12349 round_trippers.go:473]     Accept: application/json;as=Table;v=v1;g=meta.k8s.io,application/json;as=Table;v=v1beta1;g=meta.k8s.io,application/json
I0813 00:43:11.795436   12349 round_trippers.go:473]     User-Agent: kubectl/v1.26.3 (darwin/arm64) kubernetes/9e64410
I0813 00:43:11.810640   12349 round_trippers.go:574] Response Status: 200 OK in 15 milliseconds
NAME          READY   STATUS    RESTARTS   AGE
hello-world   1/1     Running   0          2m24s
```
- Same output as 7, adds Response Headers and truncated Response Body.
```
kubectl get pod hello-world -v 8 
```
- Same output as 8, add full Response. Focus on the bottom, look for metadata
```
kubectl get pod hello-world -v 9 
```

- Start up a kubectl proxy session, this will authenticate use to the API Server
Using our local `kubeconfig` for authentication and settings, updated head to only return 10 lines.
```
kubectl proxy &
curl http://localhost:8001/api/v1/namespaces/default/pods/hello-world | head -n 10

url http://localhost:8001/api/v1/namespaces/default/pods/hello-world | head -n 10
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  6672    0  6672    0     0   149k      0 --:--:-- --:--:-- --:--:--  171k
{
  "kind": "Pod",
  "apiVersion": "v1",
  "metadata": {
    "name": "hello-world",
    "namespace": "default",
    "uid": "38931dac-4a16-4c97-9e29-c47a987f8b03",
    "resourceVersion": "254587",
    "creationTimestamp": "2023-08-12T17:40:47Z",
    "annotations": {


fg
ctrl+c
```

- Watch, Exec and Log Requests
A watch on Pods will watch on the `resourceVersion` on `api/v1/namespaces/default/Pods`
```
kubectl get pods --watch -v 6 &

0813 00:47:34.773712   14835 loader.go:373] Config loaded from file:  /Users/hungts/.kube/config
I0813 00:47:34.795153   14835 round_trippers.go:553] GET https://127.0.0.1:6443/api/v1/namespaces/default/pods?limit=500 200 OK in 17 milliseconds
NAME                                        READY   STATUS    RESTARTS      AGE
hello-world                                 1/1     Running   0             6m47s
nginx-ingress-controller-7cdb66bb8c-vlsf5   1/1     Running   1 (97m ago)   9d
I0813 00:47:34.796744   14835 round_trippers.go:553] GET https://127.0.0.1:6443/api/v1/namespaces/default/pods?resourceVersion=255194&watch=true 200 OK in 0 milliseconds
```

- Delete the pod and we see the updates are written to our stdout. Watch stays, since we're watching All Pods in the default namespace.
```
kubectl delete pods hello-world
```
- Bring our Pod back
```
kubectl apply -f pod.yaml
```

- And kill off our watch
```
fg
ctrl+c
```

- Accessing logs
```
kubectl logs hello-world
kubectl logs hello-world -v 6
```

- Start kubectl proxy, we can access the resource URL directly.

```
kubectl proxy &
curl http://localhost:8001/api/v1/namespaces/default/pods/hello-world/log 
```

- Kill our kubectl proxy, fg then ctrl+c
```
fg
ctrl+c
```

- Authentication failure Demo
```
cp ~/.kube/config  ~/.kube/config.ORIG
```

- Make an edit to our username changing user: `kubernetes-admin` to user: `kubernetes-admin1`

```
vi ~/.kube/config
```

- Try to access our cluster, and we see GET https://172.16.94.10:6443/api?timeout=32s 403 Forbidden in 5 milliseconds
```
kubectl get pods -v 6
```

- Let's put our backup kubeconfig back
```
cp ~/.kube/config.ORIG ~/.kube/config
```

- Test out access to the API Server
```
kubectl get pods 
```

- Missing resources, we can see the response code for this resources is 404, it's Not Found.
```
kubectl get pods nginx-pod -v 6
```

- Let's look at creating and deleting a deployment. 
We see a query for the existence of the deployment which results in a 404, then a 201 OK on the `POST` to create the deployment which suceeds.
```
kubectl apply -f deployment.yaml -v 6
```

- Get a list of the Deployments
```
kubectl get deployment 
```

- Clean up when we're finished. We see a `DELETE` `200` `OK` and a `GET` `200` `OK`.
```
kubectl delete deployment hello-world -v 6
kubectl delete pod hello-world
```
