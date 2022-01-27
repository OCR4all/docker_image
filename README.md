# OCR4all - Docker image 

Provides OCR (optical character recognition) services through web applications

## Getting Started

These instructions will get you a [Docker container](https://www.docker.com/what-container) that runs the project

### Prerequisites

[Docker](https://www.docker.com) (for installation instructions see the [Official Installation Guide](https://docs.docker.com/install/))

### Installing

#### Get the Docker Image
From Docker Hub:
* Execute the following command ```docker pull uniwuezpd/ocr4all```

or

From Source:
* Download the [Dockerfile](IdeaProjects/docker_image/Dockerfile) first and enter the directory that contains it with a command line tool.

* Execute the following command inside the directory: ``` docker build -t <IMAGE_NAME> . ``` 

(We recommend uniwuezpd/ocr4all as image name)

#### Initialize Container
With the help of the image a container can now be created with the following command:
```
docker run \
    -p 8080:8080 \
    -u `id -u root`:`id -g $USER` \
    --name ocr4all \
    -v <OCR_DATA_DIR>:/var/ocr4all/data \
    -v <OCR_MODEL_DIR>:/var/ocr4all/models/custom \
    -it <IMAGE_NAME>
```

Explanation of variables used above:
* `<IMAGE_NAME>` - Name of the Docker image e.g. uniwuezpd/ocr4all
* `<OCR_DATA_DIR>` - Directory in which the OCR data is located on your local machine
* `<OCR_MODEL_DIR>` - Directory in which the OCR models are located on your local machine

The container will be started by default after executing the `docker run` command.

If you want to start the container again later use `docker ps -a` to list all available containers with their Container IDs and then use `docker start -ia ocr4all` to start the desired container.

You can now access the project via following URL: http://localhost:8080/ocr4all/

### Updating
#### From Docker Hub:

Updating the image can easily be done via the docker hub if the image has been previously pulled from the docker hub.

The following command will update the image:
```
docker pull uniwuezpd/ocr4all
```

#### From Source:

To update the source code of the project you currently need to reinstall the image.

This can be achieved with executing the following command first:
```
docker image rm <IMAGE_NAME>
```
Afterwards you can follow the installation guide above as it is a new clean installation.

## Development

In case you want shell access on your Docker container for development or testing purposes the container needs to be created with the following command (including the `--entrypoint` option):
```
docker run \
    -p 8080:8080 \
    --entrypoint /bin/bash \
    -v <OCR_DATA_DIR>:/var/ocr4all/data \
    -v <OCR_MODEL_DIR>:/var/ocr4all/models/custom \
    -it <IMAGE_NAME>
```

The container will be started by default after executing the `docker run` command.

If you want to start the container again later use `docker ps -a` to list all available containers with their Container IDs and then use `docker start <CONTAINER_ID>` to start the desired container. To gain shell access again use `docker attach <CONTAINER_ID>`.

Because the entrypoint has changed, processes will not start automatically and the following command needs to be executed after the container startup:
```
/usr/bin/supervisord
```

For information on how to update the project take a look into the commands within the [Dockerfile](IdeaProjects/docker_image/Dockerfile).

## Built With

* [Docker](https://www.docker.com) - Platform and Software Deployment
* [Maven](https://maven.apache.org/) - Dependency Management
* [Spring](https://spring.io/) - Java Framework
* [Materialize](http://materializecss.com/) - Front-end Framework
* [jQuery](https://jquery.com/) - JavaScript Library

## Included Projects

* [LAREX](https://github.com/chreul/LAREX) - Layout analysis on early printed books
* [OCRopus](https://github.com/tmbdev/ocropy) - Collection of document analysis programs
* [calamari](https://github.com/ChWick/calamari) - OCR Engine based on OCRopy and Kraken

