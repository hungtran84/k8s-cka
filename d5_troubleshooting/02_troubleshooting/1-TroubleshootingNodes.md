# Troubleshooting Node

Break the worker nodes to simulate the failure scenarios

- Scenario 1: Stopped kubelet

```shell
ssh <user>@<worker_node1>
sudo systemctl stop kubelet.service
sudo systemctl disable kubelet.service
```

- Scenario 2: Inaccessible config.yaml

```shell
ssh <user>@<worker_node2>
sudo mv /var/lib/kubelet/config.yaml /var/lib/kubelet/config.yml
sudo systemctl restart kubelet.service
```

- Scenario 3: Misconfigured systemd unit

```shell
ssh <user>@<worker_node3>
sudo sed -i ''s/config.yaml/config.yml/'' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
sudo systemctl daemon-reload
sudo systemctl restart kubelet.service
```

# Worker Node Troubleshooting Scenario 1

- It can take a minute for the node's status to change to NotReady...wait until they are.
Except for the master, all of the Nodes' statuses are NotReady, let's check out why...

```shell
kubectl get nodes
```


- Remember the master/control plane node still has a kubelet and runs pods...So this troubleshooting methodology can apply there.
Let's start troubleshooting node1's issues.

```
ssh <user>@<worker_node1>
```

- The kubelet runs as a systemd service/unit...so we can use those tools to troubleshoot why it's not working
Let's start by checking the status. Add no-pager so it will wrap the text
It's loaded, but it's inactive (dead)...so that means it's not running. 
We want the service to be active (running)
So the first thing to check is the service enabled?

```shell
sudo systemctl status kubelet.service
```

- If the service wasn't configured to start up by default (disabled) we can use enable to set it to.

```shell
sudo systemctl enable kubelet.service 
```

- That just enables the service to start up on boot, we could reboot now or we can start it manually
So let's start it up and see what happens...ah, it's now actice (running) which means the kubelet is online.
We also see in the journald snippet, that it's watching the apiserver. So good stuff there...

```shell
sudo systemctl start kubelet.service
sudo systemctl status kubelet.service 
```

- Log out of the node

```shell
exit
```

- is Node1 reporting Ready?

```shell
kubectl get nodes
```

- Worker Node Troubleshooting Scenario 2

```shell
ssh <user>@<worker_node2>
```

- Crashlooping kubelet...indicated by the code = exited and the status = 255
But that didn't tell us WHY the kubelet is crashlooping, just that it is...let's dig deeper

```shell
sudo systemctl status kubelet.service --no-pager
```

- systemd based systems write logs to journald, let's ask it for the logs for the kubelet
This tells us exactly what's wrong, the failed to load the Kubelet config file which it thinks is at /var/lib/kubelet/config.yaml

```shell
sudo journalctl -u kubelet.service --no-pager
```

- Let's see what's in /var/lib/kubelet/...ah, look the kubelet wants config.yaml, but we have config.yml

```shell
sudo ls -la /var/lib/kubelet 
```

- And now fixup that config by renaming the file and and restarting the kubelet
Another option here would have been to edit the systemd unit configuration for the kubelet in /etc/systemd/system/kubelet.service.d/10-kubeadm.conf.
We're going to look at that in the next demo below.

```shell
sudo mv /var/lib/kubelet/config.yml  /var/lib/kubelet/config.yaml
sudo systemctl restart kubelet.service 
```

- It should be Active(running)

```shell
sudo systemctl status kubelet.service 
```

- Lets log out

```shell
exit
```

- Node should be Ready.

```shell
kubectl get nodes
```

- Worker Node Troubleshooting Scenario 3

```shell
ssh <user>@<worker_node3>
```

- Crashlooping again...let's dig deeper and grab the logs

```shell
sudo systemctl status kubelet.service --no-pager
```

- Using journalctl we can pull the logs...this time it's looking for config.yml...

```shell
sudo journalctl -u kubelet.service --no-pager
```

- Is config.yml in /var/lib/kublet? No, it's config.yaml...but I don't want to rename this because I want the filename so it matches all the configs on all my other nodes.

```shell
sudo ls -la /var/lib/kubelet
```

- Let's reconfigure where the kubelet looks for this config file
Where is the kubelet config file specified?, check the systemd unit config for the kubelet
Where does systemd think the kubelet's config.yaml is?

```shell
sudo systemctl status kubelet.service --no-pager
sudo more /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
```

- Let's update the config args, inside here is the startup configuration for the kubelet

```shell
sudo vi /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
```

- Let's restart the kubelet...

```shell
sudo systemctl restart kubelet 
```

- But since we edited the unit file, we neede to reload the unit files (configs)...then restart the service

```shell
sudo systemctl daemon-reload
sudo systemctl restart kubelet 
```

- Check the status...active and running?

```shell
sudo systemctl status kubelet.service
```

- Log out

```shell
exit
```

- Check our Nodes' statuses

```shell
kubectl get nodes
```
