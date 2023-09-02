#!/bin/sh
#Break the scheduler control plane pod
gcloud compute ssh cp1 -- sudo cp /etc/kubernetes/manifests/kube-scheduler.yaml /tmp/kube-scheduler.yaml.ORIG
gcloud compute ssh cp1 -- sudo "sed -i 's/image: registry.k8s.io\/kube-scheduler:/image: registry.k8s.io\/kube-cheduler:/' /etc/kubernetes/manifests/kube-scheduler.yaml"
