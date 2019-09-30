# rose-demo-docker
ROSE demo in a docker, which can be developed and deployed easier.

docker-compose:

1. Official nginx docker, outer docker, base on Alpine for simplicity, pull from docker hub.
1. Main website, html5, css3, fastCGI (external files, mounted to nginx for live updates)
1. ROSE docker, run as microservice, complete the task given by nignx, inner docker, customized based on Ubuntu 16.04, expired in one hour or less.


## Deployment without Docker

#### Prerequisite

Apache2

### Configuration

Copy the ```www``` folder to ```/var/www```.

Insert the following lines to ```/etc/apache2/apache2.conf``` for CGI support.

```bash
ScriptAlias  /cgi-bin/ /var/www/cgi-bin/
<Directory /var/www/cgi-bin/>
        Options ExecCGI
        AddHandler cgi-script cgi pl
</Directory>

```

Restart Apache2.

```bash
sudo systemctl restart apache2
```

## Deployment with Docker

#### Communication between nested dockers

Single file can't be passed into a docker container. For each service request, we could create a unique temporary folder ```foo``` having that file in ```/tmp``` in the outer docker and then share the folder ```foo``` with inner docker. The output is also put in the same folder. Outer docker can return it to the corresponding user. 
