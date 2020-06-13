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
