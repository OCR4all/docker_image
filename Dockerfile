FROM ls6uniwue/ocr4all_base:latest

# Start processes when container is started
ENTRYPOINT [ "/usr/bin/supervisord" ]

# Force tomcat to use java 8
RUN rm /usr/lib/jvm/default-java && \
    ln -s /usr/lib/jvm/java-1.8.0-openjdk-amd64 /usr/lib/jvm/default-java && \
    update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java

ARG ARTIFACTORY_URL=http://artifactory-ls6.informatik.uni-wuerzburg.de/artifactory/libs-snapshot/de/uniwue

# Create ocr4all directories and grant tomcat permissions
RUN mkdir -p /var/ocr4all/data && \
    mkdir -p /var/ocr4all/models/default && \
    mkdir -p /var/ocr4all/models/custom && \
    chmod -R g+w /var/ocr4all && \
    chgrp -R tomcat8 /var/ocr4all

# Make pretrained CALAMARI models available to the project environment
## Update to future calamari version v1.x.x will require new models
ARG CALAMARI_MODELS_VERSION="0.3"
RUN wget https://github.com/OCR4all/ocr4all_models/archive/${CALAMARI_MODELS_VERSION}.tar.gz -O /opt/ocr4all_models.tar.gz && \
    mkdir -p /opt/ocr4all_models/ && \
    tar -xvzf /opt/ocr4all_models.tar.gz -C /opt/ocr4all_models/ --strip-components=1 && \
    rm /opt/ocr4all_models.tar.gz && \
    ln -s /opt/ocr4all_models/default /var/ocr4all/models/default/default;


# Install ocropy, make all ocropy scripts available to JAVA environment
ARG OCROPY_COMMIT="d1472da2dd28373cda4fcbdc84956d13ff75569c"
RUN cd /opt && git clone -b master https://gitlab2.informatik.uni-wuerzburg.de/chr58bk/mptv.git ocropy && \
    cd ocropy && git reset --hard ${OCROPY_COMMIT} && \
    python2.7 setup.py install && \
    for OCR_SCRIPT in `cd /usr/local/bin && ls ocropus-*`; \
        do ln -s /usr/local/bin/$OCR_SCRIPT /bin/$OCR_SCRIPT; \
    done

# Install calamari, make all calamari scripts available to JAVA environment
## calamari from source with version: v0.x.x
ARG CALAMARI_COMMIT="6433677ae773e0af8d53606c166726832809996b" 
RUN cd /opt && git clone -b calamari-0.3 https://github.com/Calamari-OCR/calamari.git && \
    cd calamari && git reset --hard ${CALAMARI_COMMIT} && \
    python3 setup.py install && \
    for CALAMARI_SCRIPT in `cd /usr/local/bin && ls calamari-*`; \
        do ln -s /usr/local/bin/$CALAMARI_SCRIPT /bin/$CALAMARI_SCRIPT; \
    done

# Install helper scripts to make all scripts available to JAVA environment
ARG HELPER_SCRIPTS_COMMIT="3e82d303d494a8de2208baf4c0044cdd268ac7dd"
RUN cd /opt && git clone -b master https://github.com/OCR4all/OCR4all_helper-scripts.git && \
    cd OCR4all_helper-scripts && git reset --hard ${HELPER_SCRIPTS_COMMIT} && \
    python3 setup.py install 

# Download maven project
ENV OCR4ALL_VERSION="0.1.2-4" \
    GTCWEB_VERSION="0.0.1-6" \
    LAREX_VERSION="0.2.3"
RUN cd /var/lib/tomcat8/webapps && \
    wget $ARTIFACTORY_URL/OCR4all_Web/$OCR4ALL_VERSION/OCR4all_Web-$OCR4ALL_VERSION.war -O OCR4all_Web.war && \
    wget $ARTIFACTORY_URL/GTC_Web/$GTCWEB_VERSION/GTC_Web-$GTCWEB_VERSION.war -O GTC_Web.war && \
    wget $ARTIFACTORY_URL/Larex/$LAREX_VERSION/Larex-$LAREX_VERSION.war -O Larex.war

# Add webapps to tomcat
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


# Put supervisor process manager configuration to container
COPY supervisord.conf /etc/supervisor/conf.d

# Create index.html for calling url without tool url part!
COPY index.html /usr/share/tomcat8/webapps/ROOT/index.html

# Copy larex.config
COPY larex.config /larex.config
ENV LAREX_CONFIG=/larex.config
