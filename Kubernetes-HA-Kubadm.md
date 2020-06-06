References:
https://kubernetes.io/blog/2019/06/24/automated-high-availability-in-kubeadm-v1.15-batteries-included-but-swappable/
https://octetz.com/docs/2019/2019-03-26-ha-control-plane-kubeadm/

Why odd number master and quorum deatils?
https://github.com/etcd-io/etcd/blob/master/Documentation/faq.md
https://github.com/etcd-io/etcd/releases/

Kubeadm config file Ref:
https://pkg.go.dev/k8s.io/kubernetes@v1.18.3/cmd/kubeadm/app/apis/kubeadm?tab=versions
https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/
https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta2#ClusterConfiguration

Best practises
https://kubernetes.io/docs/tasks/administer-cluster/highly-available-master/   

Configure Heartbeat and Election Timeout Intervals for etcd Members:
https://github.com/etcd-io/etcd/blob/master/Documentation/op-guide/configuration.md

Configure Active-Passive Setup for Scheduler and Controller Manager : 
https://kubernetes.io/docs/tasks/administer-cluster/highly-available-master/
https://github.com/kubernetes/community/blob/master/contributors/design-proposals/cluster-lifecycle/ha_master.md 

Kubeadm Control flags:
https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/control-plane-flags/
https://kubernetes.io/docs/reference/command-line-tools-reference/kube-scheduler/
https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/
https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/

Pre-requisite:
Get a load balancer or VIP to manage and configure kubernetes Masters, use cloud load balancer or HAproxy or nginx
All master servers entry should be made in load balancer on port number 6443.

Step 1: Login into master01 Create kubeadm config File 
mkdir -p /etc/kubernetes/kubeadm

Step 2: configure config file
[root@suraj ~] vim /etc/kubernetes/kubeadm/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: "v1.18.0"
# REPLACE with `loadbalancer` IP
controlPlaneEndpoint: "Load balancer ip:6443"
networking:
  serviceSubnet: "10.96.0.0/12"
  podSubnet: "10.244.0.0/16"
#apiServer:
#  extraArgs:
#    apiserver-count: "3"

Setp3 : Apply kubeadm init using the config file (--upload-certs flag is used to upload the certificates that should be shared across all the control-plane instances to the cluster)

[root@suraj ~]# kubeadm init --config=/etc/kubernetes/kubeadm/kubeadm-config.yaml --upload-certs
Output:
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of the control-plane node running the following command on each as root:

  kubeadm join loadbalancerip:6443 --token xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx \
    --discovery-token-ca-cert-hash sha256:yyyyyyyyyyyyyyyyyyyyyyyy \
    --control-plane --certificate-key xyzyzyzyzyzyzyzyzyzyz

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join loadbalancerip:6443 --token token \
    --discovery-token-ca-cert-hash sha256:abcdefghizlalamalamlamwwm
	
Step 4: Create .kube dir and copy admin.conf file
[root@suraj ~] mkdir -p $HOME/.kube
[root@suraj ~] sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
[root@suraj ~] sudo chown $(id -u):$(id -g) $HOME/.kube/config

Step 5 : Join Other control-plane components i.e Master02 or master 03

Login to Master02:
[root@suraj ~] kubeadm join loadbalancerip:6443 --token xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx \
>     --discovery-token-ca-cert-hash sha256:yyyyyyyyyyyyyyyyyyyyyyyy \
>     --control-plane --certificate-key xyzyzyzyzyzyzyzyzyzyz

Login to Master03:
[root@suraj ~] kubeadm join loadbalancerip:6443 --token xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx \
>     --discovery-token-ca-cert-hash sha256:yyyyyyyyyyyyyyyyyyyyyyyy \
>     --control-plane --certificate-key xyzyzyzyzyzyzyzyzyzyz

Step 6: Verify the master nodes added by login into master01
[root@suraj ~]# kubectl get nodes
NAME                         STATUS     ROLES    AGE     VERSION
master01  NotReady   master   9m24s   v1.18.0
master02  NotReady   master   96s     v1.18.0
master03  NotReady   master   90s     v1.18.0

Step 7: Apply flannel Network
[root@suraj ~]# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
podsecuritypolicy.policy/psp.flannel.unprivileged created
clusterrole.rbac.authorization.k8s.io/flannel created
clusterrolebinding.rbac.authorization.k8s.io/flannel created
serviceaccount/flannel created
configmap/kube-flannel-cfg created
daemonset.apps/kube-flannel-ds-amd64 created
daemonset.apps/kube-flannel-ds-arm64 created
daemonset.apps/kube-flannel-ds-arm created
daemonset.apps/kube-flannel-ds-ppc64le created
daemonset.apps/kube-flannel-ds-s390x created

Step 8: Check Nodes if they are ready
[root@suraj ~]# kubectl get nodes
NAME                         STATUS   ROLES    AGE    VERSION
master01  Ready    master   12m    v1.18.0
master02  Ready    master   5m9s   v1.18.0
master03  Ready    master   5m3s   v1.18.0

Step 9: Check all control-plane pods (YOU will See 3 etcd,kubeapiserver,kube-scheduler etc..)
[root@suraj ~]# kubectl get pods -n kube-system


10. Join Worker nodes 

Login to Worker01 and run :

kubeadm join loadbalancerip:6443 --token token \
    --discovery-token-ca-cert-hash sha256:abcdefghizlalamalamlamwwm


