# ENTRYPOINT 
```
#!/bin/bash -e
if [ $1 == 'standard' ]
then
   java -jar /var/gerrit/bin/gerrit.war init --batch --install-all-plugins -d /var/gerrit
   git config -f /var/gerrit/etc/gerrit.config gerrit.canonicalWebUrl "${CANONICAL_WEB_URL:-http://$HOSTNAME}"
   if [ ${HTTPD_LISTEN_URL} ];
   then
      git config -f /var/gerrit/etc/gerrit.config httpd.listenUrl ${HTTPD_LISTEN_URL}
   fi
   echo "Running Gerrit...."
   exec /var/gerrit/bin/gerrit.sh run

elif [ $1 == 'customized' ]
then
   echo "RUN Customized Script"
   java -jar /var/gerrit/bin/gerrit.war init -d /var/gerrit
   echo "Running Gerrit Customized...."
   exec /var/gerrit/bin/gerrit.sh run

else
   echo "COMMAND LINE ARGUMENT REQUIRED TO RUN THE BASH"
fi
```

# Dockerfile
```
FROM gerritcodereview/gerrit:3.1.0
ADD entrypoint.sh /
USER gerrit
ENV CANONICAL_WEB_URL=
ENV HTTPD_LISTEN_URL=
EXPOSE 29418 8080
VOLUME ["/var/gerrit/git", "/var/gerrit/index", "/var/gerrit/cache", "/var/gerrit/db", "/var/gerrit/etc"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["customized"]
```
# Docker push steps
```
docker tag hypoc-jenkins pritishr00/hypoc-jenkins
docker push pritishr00/hypoc-jenkins 

docker tag 7b9b13f7b9c0 ubuntu/dev:v1.6.14.2017

docker build -t gerrit:v1 .
docker tag gerrit:v1 pritishr00/gerrit:v1

BUILD NEW image and push to same repository
docker build .
docker tag 882d3971e181 pritishr00/gerrit:v2

To push a new tag to this repository,
docker push pritishr00/gerrit:tagname
```

# HEAD Less Service Access
```
podname.headlessservice.namespace.svc.cluster-domain.example.com
mysql-0.mysql-h.default.svc.cluster.local
mysql-1.mysql-h.default.svc.cluster.local
```