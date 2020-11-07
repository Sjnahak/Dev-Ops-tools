#!/bin/bash
rm -rf /var/lib/etcd
rm -rf $HOME/.kube/config
rm -rf /etc/kubernetes/

kubeadm reset
rm -rf $HOME/.kube/config
kubeadm init --apiserver-advertise-address=ip --pod-network-cidr=10.244.0.0/16
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
sudo cp -i /etc/kubernetes/admin.conf /home/suraj/.kube/config
su suraj
sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
exit
systemctl stop firewalld
systemctl stop kubelet
systemctl stop docker
iptables --flush
#iptables -tnat --flush
systemctl start kubelet
systemctl start docker
service iptables save
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl create clusterrolebinding permissive-binding --clusterrole=cluster-admin --user=admin --user=kubelet --group=system:serviceaccounts
https://github.com/jenkinsci/kubernetes-plugin/blob/master/src/main/kubernetes/service-account.yml
https://www.alibabacloud.com/blog/kubernetes-demystified-solving-service-dependencies_594110 --pod dependecncy
