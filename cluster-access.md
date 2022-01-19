# Steps to add new user in cluster

1. Generating private key for John (john.key)
```
$ openssl genrsa -out john.key 2048
Generating certificate signing request (john.csr)

$ openssl req -new -key john.key -out john.csr -subj "/CN=john/O=finance" (finance is group or namespace)
you will get (john.key)
```

2. Copy kubernetes ca certificate and key from the master node kmaster
```
We need kubernetes master servers ca.crt and ca.key to generate sign request
$ scp root@kmaster:/etc/kubernetes/pki/ca.{crt,key} .
```

3. Sign the certificate using certificate authority
```
$ openssl x509 -req -in john.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out john.crt -days 365 or 3650 for 10 years
output :(johncrt)
```

# Method1:
1.kubectl --kubeconfig readonly-kubeconfig config set-cluster kubernetes --server https://kubernetsclusterip:6443 --certificate-authority=ca.crt
2. kubect --kubeconfig readonly-kubeconfig config set-credentials readonly --client-certificate /home/readonly.crt --client-key=/home/readonly.key
3. kubectl --kubeconfig readonly-kubeconfig config set-context readonly-kubernetes --cluster kubernetes --namespaces finance --user=readonly

# Method 2:
4. Now create kubeconfig file and send to user
# We required ca.crt john.crt and john.key
```
cp ~/.kube/config john.kubeconfig
 now edit here change
 -context:
   cluster: kubernetes
   user: john
   name: john-kubernetes
 current-context : john-kubernetes
 users:
 - name :john
      client-certificate-data : base 64 output of command cat john.crt | base64 -w0
	  client-key-data: base 64 output of command cat john.key | base64 -w0
```

#Sample Output File:
```
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://kmasterip:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: readonly  # change user name
	namespace: default
  name: readonly-kubernetes # add username-kubernetes
current-context: readonly-kubernetes #username-kubernetes
kind: Config
preferences: {}
users:
- name: readonly #username
  user:
    client-certificate-data: base 64 output of command cat john.crt | base64 -w0
    client-key-data: base 64 output of command cat john.key | base64 -w0
```
	
5. create cluster role or role and role or cluster binding accordingly
```
# Readonly https://medium.com/@rschoening/read-only-access-to-kubernetes-cluster-fcf84670b698

kubectl get role * for all api and resources create using fine tune
kubectl create role --help | grep kubcetl
kubectl create role john-finance --verb=get,list --resources=* or pods --namespaces=* or specific

create role binding for group
kubect create rolebinding readonly-rolebinding --role=rolename --group=groupname --namespace namespacename
kubect create rolebinfing readonly-rolebinding --role=rolename --user=john --namespace finance

# To Use Group
subject:
- apiGroup: rabc
  kind: group
  name: groupname

# Verbs "get", "list", "watch", "create", "update", "patch", "delete"
```

# K8s Dashboard
```
Install Kuberntes Dashboard:
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
```

# For Read and Write Access For Dashboard
```
Readonly: http://blog.cowger.us/2018/07/03/a-read-only-kubernetes-dashboard.html
Admin : https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md
```

# Get the token for login
```
To get the token : kubectl describe sa admin-user -n kubernetes-dashboard
To describe the token : kubectl describe secret admin-user-token-fmnlz -n kubernetes-dashboard

To get the token : kubectl describe sa admin-user -n kubernetes-dashboard
To describe the token : kubectl describe secret admin-user-token-fmnlz -n kubernetes-dashboard
kubectl describe sa viewonly -n kubernetes-dashboard
```


# Provide Access to EKS Cluster
```
Get the current user configured locally:
aws sts get-caller-identity


To give admin access to eks cluster:
kubectl	edit -n kube-system config-map/aws-auth

under mapUser section : add 
 - userarn: 
   username: 
   groups: 
    - system:masters

To Give granular access use Role and rolebinding with aws-auth file:

under mapUser section : add 
 - userarn: 
   username: 
   groups: 
    - role-you-created
```
