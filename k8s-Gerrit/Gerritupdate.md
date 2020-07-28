# Creating and configuring an Gerrit Deployment authenticating against an LDAP database using Kubernetes

This project details steps used to set up gerrit deployment using kubernetes.


## Table of Contents
- [Creating an LDAP container](#LDAP)
- [Creating an LDAP-ADMIN container](#LDAP-ADMIN)
- [Configuring the LDAP-ADMIN container](#CONFIGURE-LDAP-ADMIN)
- [Placing gerrit conf in mount path](#Gerrit-config)
- [Creating a MYSQL container](#MYSQL)
- [Creating a GERRIT container](#GERRIT)

## LDAP
#### 1. create a PersistentVolumeClaim using persistent disks
    a. create a pvc manifest file
    cat > ldap-volumeclaim.yaml

    kind: PersistentVolumeClaim
    apiVersion: v1
    metadata:
      name: ldap-volumeclaim
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 200Gi

    b. deploy the manifest
    kubectl claim -f ldap-volumeclaim.yaml

    c. check to see if the claim has been bound
    kubectl get pvc

#### 2. create a Kubernetes secret to store the password for the admin user
    a. kubectl create secret generic ldap --from-literal=password=<your-admin-password>

#### 3. create an ldap Deployment
    a. create a manifest for the deployment
    cat > ldap.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    kompose.cmd: kompose convert --volumes hostPath
    kompose.version: 1.21.0 (992df58d8)
  creationTimestamp: null
  labels:
    io.kompose.service: ldap
  name: ldap
spec:
  replicas: 1
  selector:
    matchLabels:
      io.kompose.service: ldap
  strategy:
    type: Recreate
  template:
    metadata:
      annotations:
        kompose.cmd: kompose convert --volumes hostPath
        kompose.version: 1.21.0 (992df58d8)
      creationTimestamp: null
      labels:
        io.kompose.service: ldap
    spec:
      containers:
      - env:
        - name: LDAP_ADMIN_PASSWORD
          value: secret
        image: osixia/openldap
        imagePullPolicy: ""
        name: ldap
        ports:
        - containerPort: 389
        - containerPort: 636
        resources: {}
        volumeMounts:
        - mountPath: /var/lib/ldap
          name: ldap-hostpath0
        - mountPath: /etc/ldap/slapd.d
          name: ldap-hostpath1
      restartPolicy: Always
      serviceAccountName: ""
      volumes:
      - hostPath:
          path: /external/gerrit/ldap/var
        name: ldap-hostpath0
      - hostPath:
          path: /external/gerrit/ldap/etc
        name: ldap-hostpath1
status: {}

    b. deploy the manifest
    kubectl create -f ldap.yaml

    c. check its health, it might take a couple of minutes
    kubectl get pod -l app=ldap

#### 4. create a Service to expose the ldap container and make it accessible from the ldap-admin container
    a. cat > ldap-service.yaml

apiVersion: v1
kind: Service
metadata:
  annotations:
    kompose.cmd: kompose convert --volumes hostPath
    kompose.version: 1.21.0 (992df58d8)
  creationTimestamp: null
  labels:
    io.kompose.service: ldap
  name: ldap
spec:
  ports:
  - name: "389"
    port: 389
    targetPort: 389
  - name: "636"
    port: 636
    targetPort: 636
  selector:
    io.kompose.service: ldap
status:
  loadBalancer: {}

    b. deploy the manifest and launch the service
    kubectl create -f ldap-service.yaml

    c. check the health of the created service
    kubectl get service ldap
    
#### 5. view more details about the deployment
    a. kubectl describe deploy -l app=ldap

#### 6. view more details about the pod
    a. kubectl describe po -l app=ldap

## LDAP-ADMIN
#### 1. create an ldap-admin Deployment
    a. create a manifest for the deployment
    cat > ldap-admin.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    kompose.cmd: kompose convert --volumes hostPath
    kompose.version: 1.21.0 (992df58d8)
  creationTimestamp: null
  labels:
    io.kompose.service: ldap-admin
  name: ldap-admin
spec:
  replicas: 1
  selector:
    matchLabels:
      io.kompose.service: ldap-admin
  strategy: {}
  template:
    metadata:
      annotations:
        kompose.cmd: kompose convert --volumes hostPath
        kompose.version: 1.21.0 (992df58d8)
      creationTimestamp: null
      labels:
        io.kompose.service: ldap-admin
    spec:
      containers:
      - env:
        - name: PHPLDAPADMIN_LDAP_HOSTS
          value: ldap
        image: osixia/phpldapadmin
        imagePullPolicy: ""
        name: ldap-admin
        ports:
        - containerPort: 443
        resources: {}
      restartPolicy: Always
      serviceAccountName: ""
      volumes: null
status: {}
		  
    b. deploy the manifest
    kubectl create -f ldap-admin.yaml

    c. check its health, it might take a couple of minutes
    kubectl get pod -l app=ldap-admin

#### 4. create a Service to expose the ldap-admin container and make it accessible from the public
    a. cat > ldap-admin-service.yaml

apiVersion: v1
kind: Service
metadata:
  annotations:
    kompose.cmd: kompose convert --volumes hostPath
    kompose.version: 1.21.0 (992df58d8)
  creationTimestamp: null
  labels:
    io.kompose.service: ldap-admin
  name: ldap-admin
spec:
  ports:
  - name: "6443"
    port: 6443
    targetPort: 443
  selector:
    io.kompose.service: ldap-admin
status:
  loadBalancer: {}

    b. deploy the manifest and launch the service
    kubectl create -f ldap-admin-service.yaml

    c. check the health of the created service
    kubectl get service ldap-admin
    
#### 5. view more details about the deployment
    a. kubectl describe deploy -l app=ldap-admin

#### 6. view more details about the pod
    a. kubectl describe po -l app=ldap-admin

#### 7. visit the app in the browser using the EXTERNAL-IP value obtained from Service details

## CONFIGURE-LDAP-ADMIN
#### 1. create a posix group (e.g. gerrit-users) so as to be able to create user accounts
    a. 
    b. 
    c. 
    d. 
    e. 

#### 2. create users for use on gerrit
    a. 
    b. 
    c. 
    d.
    e. 
    f. 
    g. 
#### N.B. the first login on gerrit becomes the admin user so choose a "cn" wisely

## Gerrit-config
1. Create Directory mkdir /external/gerrit/etc/gerrit.config
[gerrit]
        basePath = git
        serverId = be5b6b2d-c164-4935-b39c-3454ce24b26a
        canonicalWebUrl = http://localhost
#[database]
#        poolMaxIdle = 24
#        poolLimit = 20
#        type = mysql
#        hostname = db
#        port = {dbport}
#        database = reviewdb?useSSL=false
#        username = gerrit2
[index]
        type = LUCENE
[auth]
        type = DEVELOPMENT_BECOME_ANY_ACCOUNT
[container]
        user = root
        javaOptions = "-Dflogger.backend_factory=com.google.common.flogger.backend.log4j.Log4jBackendFactory#getInstance"
        javaOptions = "-Dflogger.logging_context=com.google.gerrit.server.logging.LoggingContext#getInstance"
        javaOptions = -Djava.security.egd=file:/dev/./urandom
        javaOptions = --add-opens java.base/java.net=ALL-UNNAMED
        javaOptions = --add-opens java.base/java.lang.invoke=ALL-UNNAMED
[receive]
        enableSignedPush = false
[sendemail]
        smtpServer = localhost
[sshd]
        listenAddress = *:29418
[httpd]
        listenUrl = http://*:8080/
[cache]
        directory = cache

## MYSQL  Note : Have to update with statefulsets
#### 1. create a PersistentVolumeClaim using persistent disks
    a. create a pvc manifest file
    cat > mysql-volumeclaim.yaml

    kind: PersistentVolumeClaim
    apiVersion: v1
    metadata:
      name: mysql-volumeclaim
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 200Gi

    b. deploy the manifest
    kubectl claim -f mysql-volumeclaim.yaml

    c. check to see if the claim has been bound
    kubectl get pvc

#### 2. create a mysql Deployment
    a. create a manifest for the deployment
    cat > mysql.yaml

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: mysql
      labels:
        app: mysql
        role: database
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: mysql
      template:
        metadata:
          labels:
            app: mysql
            role: database
        spec:
          containers:
            - image: docker.io/mysql/mysql-server:5.7
                  name: mysql
                  ports:
                    - containerPort: <your-port-number>
                      name: mysql
          volumes:
            - name: mysql-persistent-storage
              persistentVolumeClaim:
                claimName: mysql-volumeclaim

    b. deploy the manifest
    kubectl create -f mysql.yaml

    c. check its health, it might take a couple of minutes
    kubectl get pod -l app=mysql

#### 3. create a Service to expose the mysql container and make it accessible from the other containers
    a. cat > mysql-service.yaml

    apiVersion: v1
    kind: Service
    metadata:
      name: mysql
      labels:
        app: mysql
    spec:
      type: ClusterIP
      ports:
        - port: <your-port-number>
          targetPort: 3306
      selector:
        app: mysql

    b. deploy the manifest and launch the service
    kubectl create -f mysql-service.yaml

    c. check the health of the created service
    kubectl get service mysql
    
#### 4. view more details about the deployment
    a. kubectl describe deploy -l app=mysql

#### 5. view more details about the pod
    a. kubectl describe po -l app=mysql

#### 6. get its default password
    a. kubectl logs -l app=mysql 2>&1 | grep GENERATED

#### 7. enter container and change default password before you can start using it
    a. kubectl exec -it MYSQL5.7 bash
    b. mysql -u root -p<GENERATED PASSWORD>
    c. ALTER USER 'root'@'localhost' IDENTIFIED BY 'secret';
    d. create USER 'root'@'%' IDENTIFIED BY 'secret';

#### 8. create a database for gerrit
    a. create database gerritdb;

#### 9. create a Kubernetes secret to store the password for the new root user
    a. kubectl create secret generic mysql --from-literal=password=<your-root-password>

## GERRIT Not used as of now with hostpath is used for gerrit deployment
#### 1. create a PersistentVolumeClaim using persistent disks
    a. create a pvc manifest file
    cat > gerrit-volumeclaim.yaml

    kind: PersistentVolumeClaim
    apiVersion: v1
    metadata:
      name: gerrit-volumeclaim
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 200Gi

    b. deploy the manifest
    kubectl claim -f gerrit-volumeclaim.yaml

    c. check to see if the claim has been bound
    kubectl get pvc


#### 2. create a gerrit Deployment
    a. create a manifest for the deployment
    cat > gerrit.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    kompose.cmd: kompose convert --volumes hostPath
    kompose.version: 1.21.0 (992df58d8)
  creationTimestamp: null
  labels:
    io.kompose.service: ldap
  name: ldap
spec:
  replicas: 1
  selector:
    matchLabels:
      io.kompose.service: ldap
  strategy:
    type: Recreate
  template:
    metadata:
      annotations:
        kompose.cmd: kompose convert --volumes hostPath
        kompose.version: 1.21.0 (992df58d8)
      creationTimestamp: null
      labels:
        io.kompose.service: ldap
    spec:
      containers:
      - env:
        - name: LDAP_ADMIN_PASSWORD
          value: secret
        image: osixia/openldap
        imagePullPolicy: ""
        name: ldap
        ports:
        - containerPort: 389
        - containerPort: 636
        resources: {}
        volumeMounts:
        - mountPath: /var/lib/ldap
          name: ldap-hostpath0
        - mountPath: /etc/ldap/slapd.d
          name: ldap-hostpath1
      restartPolicy: Always
      serviceAccountName: ""
      volumes:
      - hostPath:
          path: /external/gerrit/ldap/var
        name: ldap-hostpath0
      - hostPath:
          path: /external/gerrit/ldap/etc
        name: ldap-hostpath1
status: {}
		  
    b. deploy the manifest
    kubectl create -f gerrit.yaml

    c. check its health, it might take a couple of minutes
    kubectl get pod -l app=gerrit

#### 3. create a Service to expose the gerrit container and make it accessible from the public
    a. cat > gerrit-service.yaml

    apiVersion: v1
    kind: Service
    metadata:
      name: gerrit
      labels:
        app: gerrit
    spec:
      type: LoadBalancer
      ports:
        - port: <your-port-number>
          targetPort: 8080
          protocol: TCP
      selector:
        app: gerrit

    b. deploy the manifest and launch the service
    kubectl create -f gerrit-service.yaml

    c. check the health of the created service
    kubectl get service gerrit
    
#### 4. view more details about the deployment
    a. kubectl describe deploy -l app=gerrit

#### 5. view more details about the pod
    a. kubectl describe po -l app=gerrit

#### 6. visit the app in the browser using the EXTERNAL-IP value obtained from Service details