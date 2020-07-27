## Deny All

- Run a nginx Pod with labels app=web and expose it at port 80

```
kubectl run --generator=run-pod/v1 web --image=nginx --labels app=web --expose --port 80
```

- Run a temporary Pod and make a request to web Service

```
kubectl run --generator=run-pod/v1 --rm -i -t --image=alpine test-$RANDOM -- sh
wget -qO- http://web
exit
```

- It works, then apply deny-all policy to the cluster:

```
kubectl apply -f web-deny-all.yaml
```

- Try it out. Traffic drop

```
kubectl run --generator=run-pod/v1 --rm -i -t --image=alpine test-$RANDOM -- wget -qO- --timeout=2 http://web
```

- Clean

```
kubectl delete pod web
kubectl delete service web
kubectl delete networkpolicy web-deny-all
```

## LIMIT traffic to an application

Use Case:

Restrict traffic to a service only to other microservices that need to use it.
Restrict connections to a database only to the application using it.

- Create pods

```
kubectl run --generator=run-pod/v1 apiserver --image=nginx --labels app=bookstore,role=api --expose --port 80
```

- Apply policy. Restrict the access only to other pods (e.g. other microservices) running with label app=bookstore

```
kubectl apply -f api-allow.yaml
```

- Test the Network Policy is blocking the traffic, by running a Pod without the app=bookstore label

```
kubectl run --generator=run-pod/v1 test-$RANDOM --rm -i -t --image=alpine -- sh
wget -qO- --timeout=2 http://apiserver
```

- Test the Network Policy is allowing the traffic, by running a Pod with the app=bookstore label:

```
kubectl run --generator=run-pod/v1 test-$RANDOM --rm -i -t --image=alpine --labels app=bookstore,role=frontend -- sh
wget -qO- --timeout=2 http://apiserver
```

- Cleanup

```
kubectl delete pod apiserver
kubectl delete service apiserver
kubectl delete networkpolicy api-allow
```

## ALLOW all traffic from a namespace

Use Case:

Restrict traffic to a production database only to namespaces where production workloads are deployed.
Enable monitoring tools deployed to a particular namespace to scrape metrics from the current namespace.

- Run a web server in the default namespace:

```
kubectl run --generator=run-pod/v1 web --image=nginx --labels=app=web --expose --port 80
```

- Create the prod and dev namespaces:

```
kubectl create namespace dev
kubectl label namespace/dev purpose=testing
kubectl create namespace prod
kubectl label namespace/prod purpose=production
```

- Restricts traffic to only pods in namespaces that has label purpose=production

```
kubectl apply -f web-allow-prod.yaml
```

- Query this web server from dev namespace, observe it is blocked:

```
kubectl run --generator=run-pod/v1 test-$RANDOM --namespace=dev --rm -i -t --image=alpine -- sh
wget -qO- --timeout=2 http://web.default
```

- Query it from prod namespace, observe it is allowed

```
kubectl run --generator=run-pod/v1 test-$RANDOM --namespace=prod --rm -i -t --image=alpine -- sh
wget -qO- --timeout=2 http://web.default
```

- Clean up

```
kubectl delete networkpolicy web-allow-prod
kubectl delete pod web
kubectl delete service web
kubectl delete namespace {prod,dev}
```
