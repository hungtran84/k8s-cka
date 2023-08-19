# Ingress

- Create nginx ingress on your cloud provider (azure/gcp/aws…)

```
kubectl apply -f nginx-ingress.yaml
```


- Check the status of the pods to see if the ingress controller is online.

```
kubectl get pods --namespace ingress-nginx
```

Example:

```
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-hnlsq        0/1     Completed   0          3m6s
ingress-nginx-admission-patch-bds42         0/1     Completed   1          3m5s
ingress-nginx-controller-69d6546d6d-b6lvp   1/1     Running     0          3m18s
```

- Now let's check to see if the service is online

```
kubectl get services --namespace ingress-nginx
```

Example:

```
NAME                                 TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.0.134.85   52.227.171.191   80:30697/TCP,443:30217/TCP   4m49s
ingress-nginx-controller-admission   ClusterIP      10.0.138.37   <none>           443/TCP                      4m50s
```

- Create a deployment, scale it to 2 replicas and expose it as a service.
This service will be ClusterIP and we'll expose this service via the Ingress.

```
kubectl create deployment hello-world-service-single --image=ghcr.io/hungtran84/hello-app:1.0
kubectl scale deployment hello-world-service-single --replicas=2
kubectl expose deployment hello-world-service-single --port=80 --target-port=8080 --type=ClusterIP
```


- Create a single Ingress routing to the one backend service on the service port 80 

```
kubectl apply -f ingress-single.yaml
```


- Get the status of the ingress. It's routing for all host names on that public IP on port 80

```
kubectl get ingress
```

```
kubectl get services --namespace ingress-nginx
```

Example:

```
NAME                                 TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.0.134.85   52.227.171.191   80:30697/TCP,443:30217/TCP   10m
ingress-nginx-controller-admission   ClusterIP      10.0.138.37   <none>           443/TCP                      10m
```

- Describe

```
kubectl describe ingress ingress-single
```


- Access the application via the exposed ingress on the public IP

```
INGRESSIP=<EXTERNAL-IP>
curl http://$INGRESSIP
```


- Create 2 additional services

```
kubectl create deployment hello-world-service-blue --image=ghcr.io/hungtran84/hello-app:1.0
kubectl create deployment hello-world-service-red  --image=ghcr.io/hungtran84/hello-app:1.0
kubectl expose deployment hello-world-service-blue --port=4343 --target-port=8080 --type=ClusterIP
kubectl expose deployment hello-world-service-red  --port=4242 --target-port=8080 --type=ClusterIP
```

- Create an ingress with paths each routing to different backend services.

```
kubectl apply -f ingress-path.yaml
```

```
kubectl get ing
```

Example:

```
NAME             HOSTS              ADDRESS          PORTS   AGE
ingress-path     path.example.com   52.227.171.191   80      78s
ingress-single   *                  52.227.171.191   80      13m
```


- Tada!!!

```
curl http://$INGRESSIP/red  --header 'Host: path.example.com'
```

```
curl http://$INGRESSIP/blue --header 'Host: path.example.com'
```

- Add a backend to the ingress listening on path.example.com pointing to the single service

```
kubectl apply -f ingress-path-backend.yaml
```

- Hit the default backend service, single

```
curl http://$INGRESSIP/ --header 'Host: path.example.com'
```

- Route traffic to the services using named based virtual hosts rather than paths 

```
kubectl apply -f ingress-namebased.yaml
```

```
curl http://$INGRESSIP/ --header 'Host: red.example.com'
```

Output:

```
Hello, world!
Version: 1.0.0
Hostname: hello-world-service-red-56cc7b86b-dtprz
```

```
curl http://$INGRESSIP/ --header 'Host: blue.example.com'
```

Output:

```
Hello, world!
Version: 1.0.0
Hostname: hello-world-service-blue-7647475b7-hzcn9
```

- Try a name based virtual host that doesn't exist

```
curl http://$INGRESSIP/ --header 'Host: tel4vn.edu.vn'
```

## TLS

- Generate a certificate

```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/C=VN/ST=HCM/L=HCMC/O=IT/OU=IT/CN=tls.example.com"
```

- Create a secret with the key and the certificate

```
kubectl create secret tls tls-secret --key tls.key --cert tls.crt
```

- Create an ingress using the certificate and key.

```
kubectl apply -f ingress-tls.yaml
```

- Try it

```
curl https://tls.example.com:443 --resolve tls.example.com:443:$INGRESSIP --insecure --verbose
* Added tls.example.com:443:52.227.171.191 to DNS cache
* Hostname tls.example.com was found in DNS cache
*   Trying 52.227.171.191...
* TCP_NODELAY set
* Connected to tls.example.com (52.227.171.191) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/cert.pem
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-AES128-GCM-SHA256
* ALPN, server accepted to use h2
* Server certificate:
*  subject: C=VN; ST=HCM; L=HCMC; O=IT; OU=IT; CN=tls.example.com
*  start date: Jul 20 10:57:21 2020 GMT
*  expire date: Jul 20 10:57:21 2021 GMT
*  issuer: C=VN; ST=HCM; L=HCMC; O=IT; OU=IT; CN=tls.example.com
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7f9e9a80a200)
> GET / HTTP/2
> Host: tls.example.com
> User-Agent: curl/7.64.1
> Accept: */*
> 
* Connection state changed (MAX_CONCURRENT_STREAMS == 128)!
< HTTP/2 200 
< server: nginx/1.17.10
< date: Mon, 20 Jul 2020 11:01:03 GMT
< content-type: text/plain; charset=utf-8
< content-length: 82
< strict-transport-security: max-age=15724800; includeSubDomains
< 
Hello, world!
Version: 1.0.0
Hostname: hello-world-service-single-dc7d9bccf-mq675
* Connection #0 to host tls.example.com left intact
* Closing connection 0
```

- Clean up from our demo

```
kubectl delete ingresses ingress-path
kubectl delete ingress ingress-tls
kubectl delete ingress ingress-namebased
kubectl delete deployment hello-world-service-single
kubectl delete deployment hello-world-service-red
kubectl delete deployment hello-world-service-blue
kubectl delete service hello-world-service-single
kubectl delete service hello-world-service-red
kubectl delete service hello-world-service-blue
kubectl delete secret tls-secret
```

- Delete the ingress, ingress controller and other configuration elements

```
kubectl delete -f nginx-ingress.yaml
```

## Troubleshoot

- Check the Nginx Configuration

```
kubectl get pods -n ingress-nginx
kubectl exec -it -n ingress-nginx nginx-ingress-controller-67956bf89d-fv58j -- cat /etc/nginx/nginx.conf
```

- Debug logging
Using the flag --v=XX it is possible to increase the level of logging. This is performed by editing the deployment.
--v=2 shows details using diff about the changes in the configuration in nginx
--v=3 shows details about the service, Ingress rule, endpoint changes and it dumps the nginx configuration in JSON format
--v=5 configures NGINX in debug mode

```
kubectl edit deploy -n ingress-nginx nginx-ingress-controller
Add --v=X to "- args", where X is an integer
```

