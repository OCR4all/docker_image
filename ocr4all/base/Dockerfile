# Base Image which contains basic dependencies for all images building on top
FROM tomcat:9.0-jdk8

ENV CALAMARI_VERSION=2.1.2
ENV KRAKEN_VERSION=3.0.4

MAINTAINER Maximilian Nöth

# Enable Networking on port 8080 (Tomcat)
EXPOSE 8080

# Install system dependencies
RUN apt-get update && \
    apt-get install -y \
    git \
    maven \
    python3 python3-pip \
    wget \
    curl

# Install python dependencies
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --no-cache-dir calamari-ocr==$CALAMARI_VERSION kraken==$KRAKEN_VERSION

# Create ocr4all directories and grant tomcat permissions
RUN mkdir -p /var/ocr4all/data && \
    mkdir -p /var/ocr4all/models/default && \
    mkdir -p /var/ocr4all/models/custom && \
    chmod -R g+w /var/ocr4all

# Make pretrained CALAMARI models available to the project environment
RUN git clone --depth 1 https://github.com/Calamari-OCR/calamari_models /var/ocr4all/models/default
