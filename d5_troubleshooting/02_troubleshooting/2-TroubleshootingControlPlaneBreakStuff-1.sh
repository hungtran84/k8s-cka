#!/bin/bash

#Run this on your master...moving the static pod manifests to a path different 
#than the one specifed in the kubelet's config.yaml
sudo mv /etc/kubernetes/manifests/ /etc/kubernetes/manifests.wrong
sleep 10
