### Coredns (or kube-dns) is stuck in the Pending state

This is expected and part of the design. kubeadm is network provider-agnostic, so the admin should install the pod network solution of choice. You have to install a Pod Network before CoreDNS may be deployed fully. Hence the Pending state before the network is set up.


### HostPort services do not work

The HostPort and HostIP functionality is available depending on your Pod Network provider. Please contact the author of the Pod Network solution to find out whether HostPort and HostIP functionality are available.

Calico, Canal, and Flannel CNI providers are verified to support HostPort.

For more information, see the CNI portmap documentation.

If your network provider does not support the portmap CNI plugin, you may need to use the NodePort feature of services or use HostNetwork=true

### Pods are not accessible via their Service IP

Many network add-ons do not yet enable hairpin mode which allows pods to access themselves via their Service IP. This is an issue related to CNI. Please contact the network add-on provider to get the latest status of their support for hairpin mode.

### TLS certificate errors

The following error indicates a possible certificate mismatch.

``` 
kubectl get pods
Unable to connect to the server: x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "kubernetes")
Verify that the $HOME/.kube/config file contains a valid certificate, and regenerate a certificate if necessary. The certificates in a kubeconfig file are base64 encoded. The base64 --decode command can be used to decode the certificate and openssl x509 -text -noout can be used for viewing the certificate information.
```

Unset the KUBECONFIG environment variable using:

```
unset KUBECONFIG
```

Or set it to the default KUBECONFIG location:

```
export KUBECONFIG=/etc/kubernetes/admin.conf
```

Another workaround is to overwrite the existing kubeconfig for the "admin" user:

```
mv  $HOME/.kube $HOME/.kube.bak
mkdir $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```