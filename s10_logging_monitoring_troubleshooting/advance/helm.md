# How To Install Helm 3 and Configure it on Kubernetes

![How%20To%20Install%20Helm%203%20and%20Configure%20it%20on%20Kubernet%202665e58d645d481d9551257f6425b036/helm-installation-setup-1200x385.jpg](How%20To%20Install%20Helm%203%20and%20Configure%20it%20on%20Kubernet%202665e58d645d481d9551257f6425b036/helm-installation-setup-1200x385.jpg)

This post explains how to install helm 3 on kubernetes and configure components for managing and [deploying applications on the Kubernetes](https://devopscube.com/kubernetes-deployment-tutorial/) cluster.

### Prerequisites

You should have the following before getting started with the helm setup.

1. The Kubernetes cluster API endpoint should be reachable from the machine you are running helm.
2. Authenticate the cluster using kubectl and it should have cluster-admin permissions.

### Helm 3 Architecture

In helm 3 there is no tiller component. Helm client directly interacts with the kubernetes API for the helm chart deployment.

### Helm 2 Architecture

In helm 2 there is a helm component called tiller which will be deployed in the kubernetes `kube-system` namespace. Tiller components is removed in helm 3 versions.

## Install Helm 3 Without Tiller

> Note: The workstation you are running should have the kubectl context set to the cluster you want to manage with Helm.

Download the latest helm 3 installation script.

```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
```

Add execute permissions to the downloaded script.

```
chmod 700 get_helm.sh
```

Execute the installation script.

```
./get_helm.sh
```

Validate helm installtion by executing the helm command.

```
helm
```

Now, add the public stable helm repo for installing the stable charts.

```
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
```

Lets install a stable nginx chart and test the setup.

```
helm install nginx stable/nginx-ingress
```

List the installed helm chart

```
helm ls
```

## Installing & Configuring Helm 2

This installation is on the client-side. ie, a personal workstation, a Linux VM, etc. You can install the helm using a single liner. It will automatically find your OS type and installs helm on it.

Execute the following from your [command line](https://devopscube.com/linux-command-line-tips-beginners/).

```
curl -L https://git.io/get_helm.sh | bash
```

### Create Tiller Service Account With Cluster Admin Permissions

Tiller is the server component for helm. Tiller will be present in the kubernetes cluster and the helm client talks to it for deploying applications using helm charts.

Helm will be managing your cluster resources. So we need to add necessary permissions to the tiller components which resides in the cluster `kube-system` namespace.

Here is what we will do,

1. Create a ClusterRoleBinding with cluster-admin permissions to the tiller service account.

We will add both service account and clusterRoleBinding in one yaml file.

Create a file named `helm-rbac.yaml` and copy the following contents to the file.

```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system

```

Lets create these resources using kubectl

```
kubectl apply -f helm-rbac.yam
```

### Initialize Helm: Deploy Tiller

Next step is to initialize helm. When you initialize helm, a deployment named tiller-deploy will be deployed in the kube-system namespace.

Initialize helm using the following command.

```
helm init --service-account=tiller --history-max 300
```

If you want a specific tiller version to be installed, you can specify the tiller image link in the init command using `--tiller-image` flag. You can find the all tiller docker images in [public google GCR registry.](https://console.cloud.google.com/gcr/images/kubernetes-helm/GLOBAL/tiller?gcrImageListsize=30)

```
helm init --service-account=tiller --tiller-image=gcr.io/kubernetes-helm/tiller:v2.14.1   --history-max 300
```

If you dont mention “–service-account=tiller”, you will get the following error.

```
Error: no available release name found
```

You can check the tiller deployment in the kube-system namespace using kubectl.

```
kubectl get deployment tiller-deploy -n kube-system
```

### Deploy a Sample App Using Helm

Now lets deploy a sample [nginx ingress](https://devopscube.com/setup-ingress-kubernetes-nginx-controller/) using helm.

Execute the following helm install command to deploy an nginx ingress in the kubernetes cluster. It will download the nginx-ingress helm chart from the [public github helm chart repo](https://github.com/helm/charts/tree/master/stable).

```
helm install stable/nginx-ingress --name nginx-ingress
```

You can check the install helm chart using the following command.

```
helm ls
```

You can delete the sample deployment using delete command. For example,

```
helm delete nginx-ingress
```

### Remove Helm (Tiller) From Kubernetes Cluster

If you want to remove the tiller installtion from the kubernetes cluster use the following command.

```
helm reset
```

For some reason, if it throws error, force remove it using the following command.

```
helm reset --force
```

Also you can use the kubectl command to remove it.

```
kubectl delete deployment tiller-deploy --namespace kube-system
```

In the next blog post, we will look in to chart development and best practices of HELM

### You'll also like: