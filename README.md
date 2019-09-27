# rose-demo-docker
ROSE demo in a docker, which can be developed and deployed easier.

docker-compose:

1. nginx docker, outer docker
1. main website, html5, css3, fastCGI (external files, copied to nginx)
1. rose docker, run as microservice, complete the task given by nignx, inner docker
