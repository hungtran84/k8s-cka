#Demo 1 - Creating and Scaling a Deployment.
#Let's start off imperatively creating a deployment and scaling it...
kubectl run hello-world --image=gcr.io/google-samples/hello-app:1.0


#Check out the status of our deployment, we get 1 Replica
kubectl get deployments hello-world


#Let's scale our deployment from 1 to 10 replicas
kubectl scale deployments hello-world --replicas=10


#Check out the status of our deployment, we get 10 Replicas
kubectl get deployments hello-world


#But we're going to want to use Declarative deployments in yaml, so let's delete this.
kubectl delete deployment hello-world


#Deploy our Deployment via yaml, look inside deployment.yaml first.
kubectl apply -f deployment.yaml 


#Check the status of our deployment
kubectl get deployments hello-world


#Apply a modified yaml file scaling from 10 to 20 replicas.
kubectl apply -f deployment.20replicas.yaml
kubectl get deployments hello-world


#Clean up from our demos
kubectl delete deployment hello-world
kubectl delete service hello-world
