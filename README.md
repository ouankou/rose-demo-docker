# rose-demo-docker
ROSE demo in a docker, which can be developed and deployed easier.

docker-compose:

1. nginx docker, outer docker
1. main website, html5, css3, fastCGI (external files, mounted to nginx for live updates)
1. rose docker, run as microservice, complete the task given by nignx, inner docker


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
