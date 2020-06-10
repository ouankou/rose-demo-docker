# rose-demo-docker
ROSE demo in a docker, which can be developed and deployed easier.

### Create ROSE docker image

```bash
docker build -t rose-demo -f Dockerfile.rose .
```

### Start the ROSE docker container

```bash
docker run -it rose-demo bash
```

# The rest of instructions are out-dated and need significant revision first.

## Components

1. Outer docker, base on the official dind-rootless docker, which is based on Alpine Linux. It's pulled from docker hub. Apache2 is installed later as webserver.
1. Main website, html5, css3, CGI scripts (external files, mounted to the outer docker for live updates).
1. ROSE docker, run as microservice, complete the task given by outer docker. It runs in rootless mode as inner docker. It's customized based on Ubuntu 16.04.

## Build dockers

Build the customized dind-rootless docker image.

```bash
# enter the repo root folder
sudo docker build -t rose-demo . -f Dockerfile.dind
```

(Work-in-Progress) Build the customized ROSE docker image.

```bash
docker build -t rose-demo -f Dockerfile.rose .
```

## Deployment

#### Start the single-layer docker

```bash
docker run -it rose-demo bash
```

#### Start the outer docker

```bash
# enter the repo root folder
sudo docker run -it --name demo_dind --privileged -p 5030:80 -v ~/Projects/rose-demo-docker/rose_www:/var/www/localhost rose-demo --experimental
```

#### Start the webserver

```bash
sudo docker exec -it --user root:root demo_dind httpd
```

#### (Work-in-Progress) Communication between nested dockers

Single file can't be passed into a docker container. For each service request, we could create a unique temporary folder ```foo``` having that file in ```/tmp``` in the outer docker and then share the folder ```foo``` with inner docker. The output is also put in the same folder. Outer docker can return it to the corresponding user. 


## Access the Demo

After local deployment, access the address localhost:5030.
For a trial run,
 1. go the identityTranslator demo.
 1. copy/paste any code in the text box.
 1. click submit
 1. In the ```Compilation message``` box, it shows the output from running hello-world inner docker.

## Dockerize the frontend

The frontend is developed using React.

#### Build

A docker image ready for use has been pushed to DockerHub.
```bash
docker pull ouankou/rose:frontend
```

#### Run
The React app uses the 5000 port by default. A proper port on the host should be mapped to that port in the docker container.
```bash
docker run -d -p 5000:5000 --name rose-react ouankou/rose:frontend
```
