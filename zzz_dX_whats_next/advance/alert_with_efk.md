# Alerting on Kubernetes Events with EFK Stack

![jeremy-yap-PQWDsr78l8w-unsplash.jpg](Alerting%20on%20Kubernetes%20Events%20with%20EFK%20Stack%20e7e70d27464b4128902b560ec2051939/jeremy-yap-PQWDsr78l8w-unsplash.jpg)

You probably care about gathering application logs only. Still, since the application is running on Kubernetes, you could get a lot of information about what is happening in the cluster by gathering events as well. Whatever happens inside the cluster, an event is recorded. You can check those events with `kubectl events`, but they are short-lived. To search or alert on a particular activity, you need to store them in a central place first. Now, let's see how to do that and then how to configure alerts.

### Storing Events In Elasticsearch

The main requirement for this setup is the Elasticsearch cluster. So, assuming you already have EFK stack, go ahead and install Metricbeat with helm:

```
$ cat > values-metricbeat.yaml<<EOF 
daemonset:
  enabled: false

deployment:
  config:
    setup.template.name: "kubernetes_events"
    setup.template.pattern: "kubernetes_events-*"
    output.elasticsearch:
      hosts: ["http://elasticsearch-efk-cluster:9200"]
      index: "kubernetes_events-%{[beat.version]}-%{+yyyy.MM.dd}"
    output.file:
      enabled: false
  modules:
    kubernetes:
      enabled: true
      config:
        - module: kubernetes
          metricsets:
            - event
EOF

$ helm install --name events \
    --namespace logging \
    -f values-metricbeat.yaml \
    stable/metricbeat

```

**NOTE:** Use your hostname in the above configuration.

Events are available through Kubernetes API, and only one Metricbeat agent pod is enough to feed all events into the Elasticsarch. The next step is to configure Kibana for the new index. Go to settings, configure index to `kubernetes_events-*`, choose a `@timestamp`, and Kibana is ready. In the discovery tab, you should see all the events from all namespaces in your Kubernetes cluster. You can search for events as needed.

**NOTE:** Metricbeat adds quite a lot of fields, and by default, the Kibana wildcard search will not work as expected because it is limited to 1024 fields. You can still search a particular field, or increase the limit.

### Configuring Alerts

Now when all events are indexed, you can send alerts when a particular query matches. After some research, I found [ElastAlert](https://github.com/Yelp/elastalert) quite excellent and simple to configure. You can install it with helm as well, again matching to your Elasticsearch host:

```
$ cat > values-elastalert.yaml<<EOF 
replicaCount: 1

elasticsearch:
  host: elasticsearch-efk-cluster
  port: 9200

realertIntervalMins: "0"

rules:
  k8s_events_killing_pod: |-
    ---
    name: Kubernetes Events
    index: kubernetes_events-*

    type: any

    filter:
    - query:
        query_string:
          query: "kubernetes.event.message: Killing*probe*"
          analyze_wildcard: true

    alert:
    - "slack"
    alert_text_type: exclude_fields
    alert_text: |
      Event count {0}
      ```{1}```
      ```
      Kind - {2}
      Name - {3}
      ```
    alert_text_args:
    - kubernetes.event.count
    - kubernetes.event.message
    - kubernetes.event.involved_object.kind
    - kubernetes.event.involved_object.name

    slack:
    slack_title: Kubernetes Events
    slack_title_link: <YOUR_KIBANA_URL_SAVED_SEARCH>
    slack_webhook_url: <YOUR_SLACK_URL>
    slack_msg_color: warning
EOF

$ helm install --name efk-alerts \
    --namespace logging \
    -f values-elastalert.yaml \
    stable/elastalert
```

In the above example, I configured ElastAlert to send an alert to a Slack channel when the pod gets killed because of the liveness probe. You need to set `slack_webhook_url` and `slack_title_link`. For slack title link I usually put saved Kibana search URL that matches the same query `kubernetes.event.message: Killing***probe*`.

ElastAlert instance can be used to add other alerts as well, like matching particular application log messages. Just add a new alert rule to `values-elastalert.yaml` and upgrade the helm chart to configure it:

```
$ helm upgrade efk-alerts \
    --namespace logging \
    -f values-elastalert.yaml \
    stable/elastalert
    
```

To learn more about all the options for ElastAlert, please check [official documents](https://elastalert.readthedocs.io/en/latest/). There are a lot of options and ways to configure it.

### Summary

This article was just a short introduction to the primary use case where you want to gather all Kubernetes events in one place and to send an alert when a particular circumstance happens. I found it very useful, and I hope it will help you as well. Stay tuned for the next one.