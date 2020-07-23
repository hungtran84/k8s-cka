# This demo will be run from c1-master1 since kubectl is already installed there.
# This can be run from any system that has the Azure CLI client installed.

ssh aen@c1-master1


#Ensure Azure CLI command line utilitles are installed
#https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list

sudo apt-key --keyring /etc/apt/trusted.gpg.d/Microsoft.gpg adv --keyserver packages.microsoft.com --recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF

sudo apt-get update
sudo apt-get apt-get install --only-upgrade azure-cli


#Log into our subscription
az login
az account set --subscription "Demonstration Account"


#Create a resource group for the serivces we're going to create (This has been pre-created because of...Azure :)
az group create --name "Kubernetes-Cloud" --location eastus2
az group show --name "Kubernetes-Cloud"


#Let's get a list of the versions available to us, 
az aks get-versions --location eastus2 -o table


#let's check out some of the options available to us when creating our managed cluster
az aks create -h | more


#Let's create our AKS managed cluster. (I pre-created this because of...Azure :)
#Default Node count: 3 
#Default VM Size: Standard_DS2_v2
az aks create \
    --resource-group "Kubernetes-Cloud" \
    --generate-ssh-keys \
    --name "k8s-cloud" \
    --node-count 3 

az aks show --resource-group  "Kubernetes-Cloud" --name "k8s-cloud"  | more 


#If needed, we can download and install kubectl on our local system.
az aks install-cli


#Get our cluster credentials and merge the configuration into our existing config file.
#This will allow us to connect to this system remotely using certificate based user authentication.
az aks get-credentials --resource-group "Kubernetes-Cloud" --name "k8s-cloud"


#List our currently available contexts
kubectl config get-contexts

#set our current context to the Azure context
kubectl config use-context k8s-cloud

#run a command to communicate with our cluster.
kubectl get nodes

#Get a list of running pods, we'll look at the system pods since we don't have anything running.
#Since the API Server is HTTP based...we can operate our cluster over the internet...esentially the same as if it was local using kubectl.
kubectl get pods --all-namespaces

#Let's set to the kubectl context back to our local custer
kubectl config use-context kubernetes-admin@kubernetes

#use kubectl get nodes
kubectl get nodes

#az aks delete --resource-group "Kubernetes-Cloud" --name "k8s-cloud" --yes --no-wait
