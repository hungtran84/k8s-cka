#!/bin/sh
#Run this script to break your CP node
gcloud compute ssh cp1 -- sudo mv /etc/kubernetes/manifests/ /etc/kubernetes/manifests.wrong

