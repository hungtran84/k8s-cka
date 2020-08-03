Install Kafka

```code
helm dependency update ./config/minikube/kafka
helm upgrade --install kafka ./config/minikube/kafka
```

Install Redis

```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade --install --values ./config/minikube/redis/redis_standalone.yaml redis bitnami/redis 
```

Use Redis

```
To get your password run:

    export REDIS_PASSWORD=$(kubectl get secret --namespace default redis -o jsonpath="{.data.redis-password}" | base64 --decode)

To connect to your Redis server:

1. Run a Redis pod that you can use as a client:
   kubectl run --namespace default redis-client --rm --tty -i --restart='Never' \
    --env REDIS_PASSWORD=$REDIS_PASSWORD \
   --image docker.io/bitnami/redis:5.0.5-debian-9-r169 -- bash

2. Connect using the Redis CLI:
   redis-cli -h redis-master -a $REDIS_PASSWORD

To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace default svc/redis-master 6379:6379 &
    redis-cli -h 127.0.0.1 -p 6379 -a $REDIS_PASSWORD
```