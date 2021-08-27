#!/bin/bash

#Disable firewalld
systemctl disable firewalld
systemctl disable firewalld
systemctl stop firewalld
yum -y update
yum -y wget
yum -y ntp
systemctl start ntpd
systemctl enable ntpd

#Disable firewalld Selinux
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i '/swap/d' /etc/fstab
swapoff -a

tee  /etc/sysconfig/modules/ipvs.modules <<-'EOF'
#!/usr/bin/env bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF

yum install ipvsadm -y

chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4

tee /etc/sysctl.d/k8s.conf <<-'EOF'
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

#If the below command doesn't work then continue with rest
sysctl -p /etc/sysctl.d/k8s.conf

yum install -y yum-utils device-mapper-persistent-data lvm2

rpm -ivh http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.107-1.el7_6.noarch.rpm
rpm -ivh https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.5-3.1.el7.x86_64.rpm
rpm -ivh https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-cli-19.03.5-3.el7.x86_64.rpm
rpm -ivh https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-19.03.5-3.el7.x86_64.rpm

systemctl start docker
systemctl enable docker

#Installing kubernetes.
tee /etc/yum.repos.d/kubernetes.repo <<-'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
EOF

yum -y install epel-release
yum makecache fast
yum install -y kubelet-1.18.0 kubectl-1.18.0 kubeadm-1.18.0 kubernetes-cni

#To setup Kube Master including networking/ fannel.
#kubeadm init --pod-network-cidr=10.244.0.0/16  --service-cidr=10.96.0.0/12 --apiserver-advertise-address=$(hostname --ip-address)
#Copy the instruction of above command output to configure the nodes.
#kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
#If Kube Master is already setup and you don't remember the token then recreate using below commands on Kube Master.
#It will create another token while prev ones still be valid
#kubeadm token create --print-join-command



