#!/bin/sh
# Use this file to break stuff on your nodes.
# Worker Node - stopped kubelet
gcloud compute ssh node1 -- sudo systemctl stop kubelet.service
gcloud compute ssh node1 -- sudo systemctl disable kubelet.service


# Worker Node - inaccessible config.yaml
gcloud compute ssh node2 -- sudo mv /var/lib/kubelet/config.yaml /var/lib/kubelet/config.yml
gcloud compute ssh node2 -- sudo systemctl restart kubelet.service


# Worker Node - misconfigured systemd unit
gcloud compute ssh node3 -- "sudo sed -i ''s/config.yaml/config.yml/'' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf"
gcloud compute ssh node3 -- sudo systemctl daemon-reload
gcloud compute ssh node3 -- sudo systemctl restart kubelet.service