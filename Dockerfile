# Base Image
FROM ubuntu:18.04
ENV DEBIAN_FRONTEND=noninteractive

ARG ARTIFACTORY_URL=http://artifactory-ls6.informatik.uni-wuerzburg.de/artifactory/libs-snapshot/de/uniwue

# Enable Networking on port 5000 (Flask), 8080 (Tomcat)
EXPOSE 5000 8080

# Installing dependencies and deleting cache
RUN apt-get update && apt-get install -y \
    locales \
    git \
    maven \
    tomcat8 \
    openjdk-8-jdk-headless \
    python2.7 python-pip python3 python3-pip python3-pil python-tk \
    wget \
    supervisor && \
    pip install scikit-image numpy matplotlib scipy lxml && \
    pip3 install lxml setuptools && \
    rm -rf /var/lib/apt/lists/*

#    python-skimage \
#    python2.7-numpy \
#    python-matplotlib \
#    python2.7-scipy \
#    python2.7-lxml \

#    python3-lxml \
#    python3-setuptools \

# Set the locale, Solve Tomcat issues with Ubuntu

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 CATALINA_HOME=/usr/share/tomcat8

# Install tensorflow
RUN pip3 install --upgrade tensorflow

# Put supervisor process manager configuration to container
RUN wget -P /etc/supervisor/conf.d https://gitlab2.informatik.uni-wuerzburg.de/chr58bk/OCR4all_Web/raw/master/supervisord.conf

# Enabling direct request in Larex submodule
#RUN sed -i 's/#directrequest:<value>/directrequest:enable/' /opt/OCR4all_Web/submodules/LAREX/Larex/src/main/webapp/WEB-INF/larex.config

# Install ocropy, make all ocropy scripts available to JAVA environment
RUN cd /opt && git clone https://gitlab2.informatik.uni-wuerzburg.de/chr58bk/mptv.git ocropy && \
    cd ocropy && python2.7 setup.py install && \
    for OCR_SCRIPT in `cd /usr/local/bin && ls ocropus-*`; \
        do ln -s /usr/local/bin/$OCR_SCRIPT /bin/$OCR_SCRIPT; \
    done

# Install calamari, make all calamari scripts available to JAVA environment
RUN cd /opt && git clone https://github.com/Calamari-OCR/calamari.git && \
    cd calamari && python3 setup.py install && \
    for CALAMARI_SCRIPT in `cd /usr/local/bin && ls calamari-*`; \
        do ln -s /usr/local/bin/$CALAMARI_SCRIPT /bin/$CALAMARI_SCRIPT; \
    done

# Make pagedir2pagexml.py available to JAVA environment
COPY pagedir2pagexml.py /bin/pagedir2pagexml.py

# Install nashi
#RUN cd /opt/OCR4all_Web/submodules/nashi/server && \
#    python3 setup.py install && \
#    python3 -c "from nashi.database import db_session,init_db; init_db(); db_session.commit()" && \
#    echo 'BOOKS_DIR="/var/ocr4all/data/"\nIMAGE_SUBDIR="/PreProc/Gray/"' > nashi-config.py
#ENV FLASK_APP nashi
#ENV NASHI_SETTINGS /opt/OCR4all_Web/submodules/nashi/server/nashi-config.py
#ENV DATABASE_URL sqlite:////opt/OCR4all_Web/submodules/nashi/server/test.db

# Force tomcat to use java 8
RUN rm /usr/lib/jvm/default-java && \
    ln -s /usr/lib/jvm/java-1.8.0-openjdk-amd64 /usr/lib/jvm/default-java && \
    update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java

ENV OCR4ALL_VERSION="0.0.2" GTCWEB_VERSION="0.0.1" LAREX_VERSION="0.0.1"

# Download maven project
RUN cd /var/lib/tomcat8/webapps && \
    wget $ARTIFACTORY_URL/OCR4all_Web/$OCR4ALL_VERSION/OCR4all_Web-$OCR4ALL_VERSION.war -O OCR4all_Web.war && \
    wget $ARTIFACTORY_URL/GTC_Web/$GTCWEB_VERSION/GTC_Web-$GTCWEB_VERSION.war -O GTC_Web.war && \
    wget $ARTIFACTORY_URL/Larex/$LAREX_VERSION/Larex-$LAREX_VERSION.war -O Larex.war
    # TODO: direct request is not enabled in this version of Larex!

# Create ocr4all directories and grant tomcat permissions
RUN mkdir -p /var/ocr4all/data && \
    mkdir -p /var/ocr4all/models/default && \
    mkdir -p /var/ocr4all/models/custom && \
    chmod -R g+w /var/ocr4all && \
    chgrp -R tomcat8 /var/ocr4all

# Make pretrained CALAMARI models available to the project environment
RUN cd /opt && git clone https://github.com/Calamari-OCR/ocr4all_models.git && \
    ln -s /opt/ocr4all_models/default /var/ocr4all/models/default/default;

RUN ln -s /var/lib/tomcat8/common $CATALINA_HOME/common && \
    ln -s /var/lib/tomcat8/server $CATALINA_HOME/server && \
    ln -s /var/lib/tomcat8/shared $CATALINA_HOME/shared && \
    ln -s /etc/tomcat8 $CATALINA_HOME/conf && \
    mkdir $CATALINA_HOME/temp && \
    mkdir $CATALINA_HOME/webapps && \
    mkdir $CATALINA_HOME/logs && \
    ln -s /var/lib/tomcat8/webapps/OCR4all_Web.war $CATALINA_HOME/webapps && \
    ln -s /var/lib/tomcat8/webapps/GTC_Web.war $CATALINA_HOME/webapps && \
    ln -s /var/lib/tomcat8/webapps/Larex.war $CATALINA_HOME/webapps

# Create index.html for calling url without tool!
COPY index.html /usr/share/tomcat8/webapps/ROOT/index.html

# Copy larex.config
COPY larex.config /larex.config

ENV LAREX_CONFIG=/larex.config

# Start processes when container is started
ENTRYPOINT [ "/usr/bin/supervisord" ]
