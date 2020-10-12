#!/bin/bash

#Break the scheduler control plane pod
sudo cp kube-scheduler.yaml /etc/kubernetes/manifests
sudo chmod 400 /etc/kubernetes/manifests/kube-scheduler.manifest
