## Recovering from a failure state

If kubeadm upgrade fails and does not roll back, for example because of an unexpected shutdown during execution, you can run kubeadm upgrade again. This command is idempotent and eventually makes sure that the actual state is the desired state you declare.

To recover from a bad state, you can also run `kubeadm upgrade apply --force` without changing the version that your cluster is running.

During upgrade kubeadm writes the following backup folders under /etc/kubernetes/tmp:

* kubeadm-backup-etcd-<date>-<time>
* kubeadm-backup-manifests-<date>-<time>
* kubeadm-backup-etcd contains a backup of the local etcd member data for this control-plane Node. In case of an etcd upgrade failure and if the automatic rollback does not work, the contents of this folder can be manually restored in /var/lib/etcd. In case external etcd is used this backup folder will be empty.

kubeadm-backup-manifests contains a backup of the static Pod manifest files for this control-plane Node. In case of a upgrade failure and if the automatic rollback does not work, the contents of this folder can be manually restored in /etc/kubernetes/manifests. If for some reason there is no difference between a pre-upgrade and post-upgrade manifest file for a certain component, a backup file for it will not be written.

## How it works

kubeadm upgrade apply does the following:

* Checks that your cluster is in an upgradeable state:
  * The API server is reachable
  * All nodes are in the Ready state
  * The control plane is healthy
* Enforces the version skew policies.
* Makes sure the control plane images are available or available to pull to the machine.
* Upgrades the control plane components or rollbacks if any of them fails to come up.
* Applies the new kube-dns and kube-proxy manifests and makes sure that all necessary RBAC rules are created.
* Creates new certificate and key files of the API server and backs up old files if they're about to expire in 180 days.

`kubeadm upgrade node` does the following on additional control plane nodes:

* Fetches the kubeadm ClusterConfiguration from the cluster.
* Optionally backups the kube-apiserver certificate.
* Upgrades the static Pod manifests for the control plane components.
* Upgrades the kubelet configuration for this node.

`kubeadm upgrade node` does the following on worker nodes:

* Fetches the kubeadm ClusterConfiguration from the cluster.
* Upgrades the kubelet configuration for this node.