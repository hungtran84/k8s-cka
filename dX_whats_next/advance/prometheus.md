# Kubernetes Monitoring with Prometheus

Prometheus monitoring is fast becoming one of the Docker and Kubernetes monitoring tool to use. This guide explains how to implement Kubernetes monitoring with Prometheus. You will learn how to deploy Prometheus server, metrics exporters, setup kube-state-metrics, pull, scrape and collect metrics, configure alerts with Alertmanager and dashboards with Grafana. We’ll cover how to do this manually as well as by leveraging some of the automated deployment/install methods like Prometheus operators.

![Kubernetes%20Monitoring%20with%20Prometheus%20-The%20ultimat%2082266822e1cb41289181ee0cdf99c8b7/Kubernetes-Monitoring-Guide.jpg](Kubernetes%20Monitoring%20with%20Prometheus%20-The%20ultimat%2082266822e1cb41289181ee0cdf99c8b7/Kubernetes-Monitoring-Guide.jpg)


### Why Use Prometheus for Kubernetes Monitoring

Two technology shifts took place that created a need for a new monitoring framework:

- **DevOps culture:** Prior to the emergence of DevOps, monitoring was comprised of hosts, networks and services. Now developers need the ability to easily integrate app and business related metrics as an organic part of the infrastructure, because they are more involved in the CI/CD pipeline and can do a lot of operations-debugging on their own. Monitoring needed to be democratized, made more accessible, and cover additional layers of the stack.
- **Containers and Kubernetes:** Container-based infrastructures are radically changing how we do logging, debugging, high-availability… and monitoring is not an exception. Now you have a huge number of volatile software entities, services, virtual network addresses, exposed metrics that suddenly appear or vanish. Traditional monitoring tools are not designed to handle this.

Why Prometheus Is the Right Tool for Containerized Environments

- **Multi-dimensional data model:** The model is based on [key-value pairs](https://prometheus.io/docs/concepts/data_model/), similar to how Kubernetes itself organizes infrastructure metadata using labels. It allows for flexible and accurate time series data, powering its Prometheus query language.
- **Accessible format and protocols:** Exposing prometheus metrics is a pretty straightforward task. Metrics are human readable, are in a self-explanatory format, and are published using a standard HTTP transport. You can check that the metrics are correctly exposed just using your web browser:

![Kubernetes%20Monitoring%20with%20Prometheus%20-The%20ultimat%2082266822e1cb41289181ee0cdf99c8b7/prom_kubernetes_metrics.png](Kubernetes%20Monitoring%20with%20Prometheus%20-The%20ultimat%2082266822e1cb41289181ee0cdf99c8b7/prom_kubernetes_metrics.png)

- **Service discovery:** The Prometheus server is in charge of periodically scraping the targets, so that applications and services don’t need to worry about emitting data (metrics are pulled, not pushed). These Prometheus servers have several methods to auto-discover scrape targets, some of them can be configured to filter and match container metadata, making it an excellent fit for ephemeral Kubernetes workloads.
- **Modular and highly available components:** Metric collection, alerting, graphical visualization, etc, are performed by different composable services. All these services are designed to support redundancy and sharding.

### How Prometheus compares to other Kubernetes monitoring tools

Prometheus released version 1.0 during 2016, so it’s a fairly recent technology. There were a wealth of tried-and-tested monitoring tools available when Prometheus first appeared. How does Prometheus compare with other veteran monitoring projects?

**Key-value vs dot-separated dimensions:** Several engines like StatsD/Graphite use an explicit, effectively generating a new metric per label:

```
current_active_users.free_tier = 423
current_active_users.premium = 56

```

This method can become cumbersome when trying to expose highly dimensional data (containing lots of different labels per metric). Flexible query-based aggregation becomes more difficult as well.

Imagine that you have 10 servers and want to group by error code. Using key-value, you can simply group the flat metric by `{http_code="500"}`. Using dot-separated dimensions, you will have a big number of independent metrics that you need to aggregate using expressions.

**Event logging vs metrics recording:** InfluxDB / Kapacitor are more similar to the Prometheus stack. They use label-based dimensionality and the same data compression algorithms. Influx is, however, more suitable for event logging due to its nanosecond time resolution and ability to merge different event logs. Prometheus is more suitable for metrics collection and has a more powerful query language to inspect them.

**Blackbox vs whitebox monitoring:** As we mentioned before, tools like Nagios/Icinga/Sensu are suitable for host/network/service monitoring, classical sysadmin tasks. Nagios, for example, is host-based. If you want to get internal detail about the state of your micro-services (aka [whitebox monitoring](https://insights.sei.cmu.edu/devops/2016/08/whitebox-monitoring-with-prometheus.html)), Prometheus is a more appropriate tool.

## The challenges of microservices and Kubernetes monitoring with Prometheus

There are unique challenges unique to monitoring a Kubernetes cluster(s) that need to be solved for in order to deploy a reliable monitoring / alerting / graphing architecture.

### Monitoring containers: visibility

Containers are lightweight, mostly immutable black boxes, which can present monitoring challenges… The Kubernetes API and the [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) (which natively uses prometheus metrics) solve part of this problem by exposing Kubernetes internal data such as number of desired / running replicas in a deployment, unschedulable nodes, etc.

Prometheus is a good fit for microservices because you just need to expose a metrics port, and thus don’t need to add too much complexity or run additional services. Often, the service itself is already presenting a HTTP interface, and the developer just needs to add an additional path like `/metrics`.

In some cases, the service is not prepared to serve Prometheus metrics and you can’t modify the code to support it. In that case, you need to deploy a [Prometheus exporter](https://prometheus.io/docs/instrumenting/exporters/) bundled with the service, often as a sidecar container of the same pod.

### Dynamic monitoring: changing and volatile infrastructure

As we mentioned before, ephemeral entities that can start or stop reporting any time are a problem for classical, more static monitoring systems.

Prometheus has [several autodiscover mechanisms](https://prometheus.io/docs/prometheus/latest/configuration/configuration) to deal with this. The most relevant for this guide are:

**Consul:** A tool for service discovery and configuration. Consul is distributed, highly available, and extremely scalable.

**Kubernetes:** Kubernetes SD configurations allow retrieving scrape targets from Kubernetes’ REST API and always staying synchronized with the cluster state.

**Prometheus Operator:** To automatically generate monitoring target configurations based on familiar Kubernetes label queries. We will focus on this deployment option later on.

### Monitoring new layers of infrastructure: Kubernetes components

Using Kubernetes concepts like the physical host or service port become less relevant. You need to organize monitoring around different groupings like microservice performance (with different pods scattered around multiple nodes), namespace, deployment versions, etc.

Using the label-based data model of Prometheus together with the [PromQL](https://prometheus.io/docs/prometheus/latest/querying/basics/), you can easily adapt to these new scopes.

## Kubernetes monitoring with Prometheus: Architecture overview

We will get into more detail later on, this diagram covers the basic entities we want to deploy in our Kubernetes cluster:

![Kubernetes%20Monitoring%20with%20Prometheus%20-The%20ultimat%2082266822e1cb41289181ee0cdf99c8b7/prometheus_kubernetes_diagram_overview.png](Kubernetes%20Monitoring%20with%20Prometheus%20-The%20ultimat%2082266822e1cb41289181ee0cdf99c8b7/prometheus_kubernetes_diagram_overview.png)

1 – The Prometheus servers need as much target auto discovery as possible.

- There are several options to achieve this:  Consul Prometheus Kubernetes SD plugin The Prometheus operator and its [Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
- 2 – Apart from application metrics, we want Prometheus to collect metrics related to the Kubernetes services, nodes and orchestration status.
    - [Node exporter](https://github.com/prometheus/node_exporter), for the classical host-related metrics: cpu, mem, network, etc.
    - Kube-state-metrics for orchestration and cluster level metrics: deployments, pod metrics, resource reservation, etc.
    - Kube-system metrics from internal components: kubelet, etcd, dns, scheduler, etc.
- 3 – Prometheus can configure rules to trigger alerts using PromQL, alertmanager will be in charge of managing alert notification, grouping, inhibition, etc.
- 4 – The alertmanager component configures the receivers, gateways to deliver alert notifications.
- 5 – Grafana can pull metrics from any number of Prometheus servers and display panels and Dashboards.

## How to install Prometheus

There are different ways to install Prometheus in your host or in your Kubernetes cluster:

- Directly as a single binary running on your hosts, which is fine for learning, testing and developing purposes but not appropriate for a containerized deployment.
- As a Docker container which has, in turn, several orchestration options:
    - Raw Docker containers, Kubernetes Deployments / StatefulSets, the Helm Kubernetes package manager, Kubernetes operators, etc.

Let’s get from more manual to more automated deployments:

Single binary -> Docker container -> Kubernetes Deployment -> Prometheus operator (Chapter 3)

You can directly [download and run](https://prometheus.io/download/) the Prometheus binary in your host:

```
prometheus-2.3.1.linux-amd64$ ./prometheus
level=info ts=2018-06-21T11:26:21.472233744Z caller=main.go:222 msg="Starting Prometheus"

```

Which may be nice to get a first impression of the Prometheus web interface (port 9090 by default).

A better option is to deploy the Prometheus server inside a container:

```
docker run -p 9090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml 
       prom/prometheus

```

Note that you can easily adapt this Docker container into a proper Kubernetes Deployment object that will mount the configuration from a ConfigMap, expose a service, deploy multiple replicas, etc.

```
kubectl create configmap prometheus-example-cm --from-file prometheus.yml

```

(You have a basic working prometheus.yml config file [here](https://github.com/prometheus/prometheus/blob/master/docs/getting_started.md))

And then you can apply this example yaml:

If you don’t want to configure a LoadBalancer / external IP, then you can always specify the type [NodePort](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) for your service.

After a few seconds, you should see the Prometheus pods running in your cluster:

```
kubectl get pods
NAME                                     READY     STATUS    RESTARTS   AGE
prometheus-deployment-68c5f4d474-cn5cb   1/1       Running   0          3h
prometheus-deployment-68c5f4d474-ldk9p   1/1       Running   0          3h

```

There are several configuration tweaks that you can implement at this point, such as configuring [pod antiaffinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity) to force the Prometheus server pods to be located in different nodes. We will cover the performance and high availability aspects on the fourth chapter of this guide.

A more advanced and automated option is to use the [Prometheus operator](https://github.com/coreos/prometheus-operator), covered in the third chapter of this guide. You can think of it as a meta-deployment: a deployment that manages other deployments and configures and updates them according to high-level service specifications. We will start manually configuring the Prometheus stack and in the next chapter we will use the operator to make the Prometheus deployment easily portable, declarative and flexible.

## How to monitor a Kubernetes service with Prometheus

Prometheus metrics are exposed by services through HTTP(S), and there are several advantages of this approach compared to other similar monitoring solutions:

- You don’t need to install a service agent, just expose a web port. Prometheus servers will regularly scrape (pull), so you don’t need to worry about pushing metrics or configuring a remote endpoint either.
- Several microservices already use HTTP for their regular functionality, and you can reuse that internal webserver and just add a folder like `/metrics`.
- The metrics format itself is human-readable and easy to grasp. If you are the maintainer of the microservice code, you can start publishing metrics without much complexity or learning required.

Some services are designed to expose Prometheus metrics from the ground-up (the Kubernetes kubelet, Traefik web proxy, Istio microservice mesh, etc). Some other services are not natively integrated, but can be easily adapted using an exporter. An exporter is a service that collects service stats and “translates” to Prometheus metrics ready to be scraped. There are examples of both in this chapter.

Let’s start with the best case scenario: the microservice that you are deploying already offers a Prometheus endpoint.

[Traefik](https://traefik.io/) is a reverse proxy designed to be tightly integrated with microservices and containers. A common use case for Traefik is to be used as an Ingress controller or Entrypoint, this is, the bridge between Internet and the specific microservices inside your cluster.

You have several options to [install Traefik](https://docs.traefik.io/) and a [Kubernetes-specific install guide](https://github.com/containous/traefik/blob/master/docs/user-guide/kubernetes.md). If you just want a simple Traefik deployment with Prometheus support up and running quickly, use the following snippet:

```
kubectl create -f https://raw.githubusercontent.com/mateobur/prometheus-monitoring-guide/master/traefik-prom.yaml

```

Once the Traefik pods is running and you can display the service IP:

```
kubectl get svc
NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                   AGE
kubernetes                   ClusterIP   10.96.0.1       <none>        443/TCP                   238d
prometheus-example-service   ClusterIP   10.103.108.86   <none>        9090/TCP                  5h
traefik                      ClusterIP   10.108.71.155   <none>        80/TCP,443/TCP,8080/TCP   35s

```

You can check that the Prometheus metrics are being exposed just using curl:

```
curl 10.108.71.155:8080/metrics
# HELP go_gc_duration_seconds A summary of the GC invocation durations.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 2.4895e-05
go_gc_duration_seconds{quantile="0.25"} 4.4988e-05
...

```

Now, you need to add the new target to the `prometheus.yml` conf file.

You will notice that Prometheus automatically scrapes itself:

```
  - job_name: 'prometheus'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
    - targets: ['localhost:9090']

```

Let’s add another static endpoint:

```
  - job_name: 'traefik'
    static_configs:
    - targets: ['traefik:8080']

```

If the service is in a different namespace you need to use the FQDN (i.e. `traefik.default.svc.cluster.local`)

Of course, this is a bare-minimum configuration, the [scrape config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#%3Cscrape_config%3E) supports multiple parameters.

To name a few:

- `basic_auth` and `bearer_token`: You endpoints may require authentication over HTTPS, using a classical login/password scheme or a bearer token in the request headers.
- `kubernetes_sd_configs` or `consul_sd_configs`: different endpoint autodiscovery methods.
- `scrape_interval`, `scrape_limit`, `scrape_timeout`: Different tradeoffs between precision, resilience and system load.

We will use some of these in the next chapters, as the deployed Prometheus stack gets more complete.

Patch the ConfigMap and Deployment:

```
kubectl create configmap prometheus-example-cm --from-file=prometheus.yml -o yaml --dry-run | kubectl apply -f -

kubectl patch deployment prometheus-deployment -p 
  "{"spec":{"template":{"metadata":{"labels":{"date":"`date +'%s'`"}}}}}"

```

If you access the `/targets` URL in the Prometheus web interface, you should see the Traefik endpoint UP:

![Kubernetes%20Monitoring%20with%20Prometheus%20-The%20ultimat%2082266822e1cb41289181ee0cdf99c8b7/prometheus_kubernetes_traefik.png](Kubernetes%20Monitoring%20with%20Prometheus%20-The%20ultimat%2082266822e1cb41289181ee0cdf99c8b7/prometheus_kubernetes_traefik.png)

Using the main web interface, we can locate some traefik metrics (very few of them, because we don’t have any Traefik frontends or backends configured for this example) and retrieve its values:

![Kubernetes%20Monitoring%20with%20Prometheus%20-The%20ultimat%2082266822e1cb41289181ee0cdf99c8b7/prometheus_kubernetes_traefik-2-1.png](Kubernetes%20Monitoring%20with%20Prometheus%20-The%20ultimat%2082266822e1cb41289181ee0cdf99c8b7/prometheus_kubernetes_traefik-2-1.png)

We already have a Prometheus on Kubernetes working example!

## How to monitor Kubernetes services with Prometheus exporters Monitoring apps using Prometheus exporters

It’s likely that many of the applications you want to deploy in your Kubernetes cluster do not expose Prometheus metrics out of the box. In that case, you need to bundle a [Prometheus exporter](https://prometheus.io/docs/instrumenting/exporters/), an additional process that is able to retrieve the state / logs / other metric formats of the main service and expose this information as Prometheus metrics. In other words, a Prometheus adapter.

You can deploy a pod containing the Redis server and a Prometheus sidecar container with the following command:

```
# Clone the repo if you don't have it already
git clone git@github.com:mateobur/prometheus-monitoring-guide.git
kubectl create -f prometheus-monitoring-guide/redis_prometheus_exporter.yaml

```

If you display the redis pod, you will notice it has two containers inside:

```
kubectl get pod redis-546f6c4c9c-lmf6z
NAME                     READY     STATUS    RESTARTS   AGE
redis-546f6c4c9c-lmf6z   2/2       Running   0          2m

```

Now, you just need to update the Prometheus configuration and reload like we did in the last section:

```
  - job_name: 'redis'
    static_configs:
      - targets: ['redis:9121']

```

To obtain all the redis service metrics:

![Kubernetes%20Monitoring%20with%20Prometheus%20-The%20ultimat%2082266822e1cb41289181ee0cdf99c8b7/prometheus_kubernetes_redis-1.png](Kubernetes%20Monitoring%20with%20Prometheus%20-The%20ultimat%2082266822e1cb41289181ee0cdf99c8b7/prometheus_kubernetes_redis-1.png)

How to monitor Kubernetes applications with Prometheus

## Monitoring Kubernetes cluster with Prometheus and kube-state-metrics

In addition to monitoring the services deployed in the cluster, you also want to monitor the Kubernetes cluster itself. Three aspects of cluster monitoring to consider are:

- The Kubernetes hosts (nodes) – classical sysadmin metrics such as cpu, load, disk, memory, etc.
- Orchestration level metrics – Deployment state, resource requests, scheduling and api server latency, etc.
- Internal kube-system components – Detailed service metrics for the scheduler, controller manager, dns service, etc.

The Kubernetes internal monitoring architecture has experienced some changes recently that we will try to summarize here, for more information you can read its [design proposal](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/instrumentation/monitoring_architecture.md).

### Monitoring Kubernetes components on a Prometheus stack

**Heapster:** Heapster is a cluster-wide aggregator of monitoring and event data that runs as a pod in the cluster.

![Kubernetes%20Monitoring%20with%20Prometheus%20-The%20ultimat%2082266822e1cb41289181ee0cdf99c8b7/kubernetes_monitoring_heapster.png](Kubernetes%20Monitoring%20with%20Prometheus%20-The%20ultimat%2082266822e1cb41289181ee0cdf99c8b7/kubernetes_monitoring_heapster.png)

Apart from the Kubelets/cAdvisor endpoints, you can append additional metrics sources to Heapster like kube-state-metrics (see below).

Heapster is now **DEPRECATED**, its replacement is the metrics-server.

**cAdvisor:** [cAdvisor](https://github.com/google/cadvisor) is an open source container resource usage and performance analysis agent. It is purpose-built for containers and supports Docker containers natively. In Kubernetes, cAdvisor runs as part of the Kubelet binary, any aggregator retrieving node local and Docker metrics will directly scrape the Kubelet Prometheus endpoints.

**Kube-state-metrics:** [kube-state-metrics](https://sysdig.com/blog/introducing-kube-state-metrics/) is a simple service that listens to the Kubernetes API server and generates metrics about the state of the objects such as deployments, nodes and pods. It is important to note that kube-state-metrics is just a metrics endpoint, other entity needs to scrape it and provide long term storage (i.e. the Prometheus server).

**Metrics-server:** Metrics Server is a cluster-wide aggregator of resource usage data. It is intended to be the default Heapster replacement. Again, the metrics server will only present the last datapoints and it’s not in charge of long term storage.

Thus:

- Kube-state metrics is focused on orchestration metadata: deployment, pod, replica status, etc.
- Metrics-server is focused on implementing the [resource metrics API](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/instrumentation/resource-metrics-api.md): CPU, file descriptors, memory, request latencies, etc.

### Monitoring the Kubernetes nodes with Prometheus

The Kubernetes nodes or hosts need to be monitored, we have plenty of tools to monitor a Linux host. In this guide we are going to use the Prometheus [node-exporter](https://github.com/prometheus/node_exporter):

- Its hosted by the Prometheus project itself
- Is the one that will be automatically deployed when we use the Prometheus operator in the next chapters
- Can be deployed as a DaemonSet and thus, will automatically scale if you add or remove nodes from your cluster.

You have several options to deploy this service, for example, using the DamonSet in this repo:

```
kubectl create ns monitoring 
kubectl create -f https://raw.githubusercontent.com/bakins/minikube-prometheus-demo/master/node-exporter-daemonset.yml

```

Or using [Helm / Tiller](https://docs.helm.sh/using_helm/#installing-helm):

If you want to use Helm, remember to create the [RBAC roles and service accounts](https://docs.helm.sh/using_helm/#role-based-access-control) for the tiller component before proceeding.

```
helm init --service-account tiller
helm install --name node-exporter stable/prometheus-node-exporter

```

Once the chart is installed and running, you can display the service that you need to scrape:

```
kubectl get svc 
NAME                                     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                     AGE
node-exporter-prometheus-node-exporter   ClusterIP   10.101.57.207    <none>        9100/TCP                                    17m

```

Once you add the scrape config like we did in the previous sections, you can start collecting and displaying the node metrics:

![Kubernetes%20Monitoring%20with%20Prometheus%20-The%20ultimat%2082266822e1cb41289181ee0cdf99c8b7/prometheus_monitoring_kube_node-1.png](Kubernetes%20Monitoring%20with%20Prometheus%20-The%20ultimat%2082266822e1cb41289181ee0cdf99c8b7/prometheus_monitoring_kube_node-1.png)

### Monitoring kube-state-metrics with Prometheus

Deploying and monitoring the kube-state-metrics is also a pretty straightforward task. Again, you can deploy directly like in the example below or use a Helm chart.

```
git clone https://github.com/kubernetes/kube-state-metrics.git
kubectl apply -f kube-state-metrics/kubernetes/
...
kubectl get svc -n kube-system
NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
kube-dns             ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP       13h
kube-state-metrics   ClusterIP   10.102.12.190    <none>        8080/TCP,8081/TCP   1h

```

Again, you just need to scrape that service (port 8080) in the Prometheus config. Remember to use the FQDN this time:

```
  - job_name: 'kube-state-metrics'
    static_configs:
    - targets: ['kube-state-metrics.kube-system.svc.cluster.local:8080']

```

### Monitoring Kubernetes internal components with Prometheus

There are several Kubernetes components including etcd, kube-scheduler or kube-controller that can expose its internal performance metrics using Prometheus.

Monitoring them is quite similar to monitoring any other Prometheus endpoint with two particularities:

- Which network interfaces are these processes using to listen, http scheme and security (HTTP, HTTPS, RBAC) depend on your deployment method and configuration templates.
    - Frequently, these services are only listening at localhost in the hosting node, making them difficult to reach from the Prometheus pods.
- These components may not have a Kubernetes service pointing to the pods, but you can always [create](https://humidifiermentor.com/cool-mist-humidifier/) it.

Depending on your deployment method and configuration, the Kubernetes services may be listening on the local host only, to make things easier on this example we are going to use [minikube](https://kubernetes.io/docs/setup/minikube/).

Minikube let’s you spawn a local single-node Kubernetes virtual machine in minutes.

This will work as well on your hosted cluster, GKE, AWS etc, but you will need to reach the service port either by modifying the configuration and restarting the services or providing additional network routes.

Installing minikube is a fairly [straightforward process](https://kubernetes.io/docs/tasks/tools/install-minikube/). First install the binary, then create a cluster that exposes the kube-scheduler service on all interfaces:

```
minikube start --memory=4096 --bootstrapper=kubeadm --extra-config=kubelet.authentication-token-webhook=true --extra-config=kubelet.authorization-mode=Webhook --extra-config=scheduler.address=0.0.0.0 --extra-config=controller-manager.address=0.0.0.0

```

Create a service that will point to the kube-scheduler pod:

```
kind: Service
apiVersion: v1
metadata:
  name: scheduler-service
  namespace: kube-system
spec:
  selector:
    component: kube-scheduler
  ports:
  - name: scheduler
    protocol: TCP
    port: 10251
    targetPort: 10251

```

Now you will be able to scrape the endpoint: `scheduler-service.kube-system.svc.cluster.local:10251`

## What’s next?

We already have a Prometheus deployment with 6 target endpoints: 2 “end-user” apps, 3 Kubernetes cluster endpoints and Prometheus itself. At this point the configuration is still naive and not automated, but we have a running Prometheus infrastructure.

The next chapter will cover additional components that are typically deployed together with the Prometheus service. We will start using the PromQL language to aggregate metrics, fire alerts and generate visualization dashboards.