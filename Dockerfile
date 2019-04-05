FROM ls6uniwue/ocr4all_base:latest

# Force tomcat to use java 8
RUN rm /usr/lib/jvm/default-java && \
    ln -s /usr/lib/jvm/java-1.8.0-openjdk-amd64 /usr/lib/jvm/default-java && \
    update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java

ARG ARTIFACTORY_URL=http://artifactory-ls6.informatik.uni-wuerzburg.de/artifactory/libs-snapshot/de/uniwue

ENV OCR4ALL_VERSION="0.0.4-1" \
    GTCWEB_VERSION="0.0.1-1" \
    LAREX_VERSION="0.0.1" \
    CALAMARI_COMMIT="8a2857b9a4cf66a514e344bc8b52973ab8f2882d" \
    OCROPY_COMMIT="5c18b238"

# Put supervisor process manager configuration to container
COPY supervisord.conf /etc/supervisor/conf.d

# Copy pagedir2pagexml, softlink it
COPY pagedir2pagexml.py /usr/local/bin/pagedir2pagexml.py

RUN ln -s /usr/local/pagedir2pagexml.py /bin/pagedir2pagexml.py

# Install ocropy, make all ocropy scripts available to JAVA environment
# DEBUG: TODO replace s330790 with chr58bk if pull request is accepted
RUN cd /opt && git clone https://gitlab2.informatik.uni-wuerzburg.de/s330790/mptv.git ocropy && \
    cd ocropy && git reset --hard ${OCROPY_COMMIT} && \
    python2.7 setup.py install && \
    for OCR_SCRIPT in `cd /usr/local/bin && ls ocropus-*`; \
        do ln -s /usr/local/bin/$OCR_SCRIPT /bin/$OCR_SCRIPT; \
    done

# Install calamari, make all calamari scripts available to JAVA environment
RUN cd /opt && git clone https://github.com/Calamari-OCR/calamari.git && \
    cd calamari && git reset --hard ${CALAMARI_COMMIT} && \
    python3 setup.py install && \
    for CALAMARI_SCRIPT in `cd /usr/local/bin && ls calamari-*`; \
        do ln -s /usr/local/bin/$CALAMARI_SCRIPT /bin/$CALAMARI_SCRIPT; \
    done

# Install nashi
#RUN cd /opt/OCR4all_Web/submodules/nashi/server && \
#    python3 setup.py install && \
#    python3 -c "from nashi.database import db_session,init_db; init_db(); db_session.commit()" && \
#    echo 'BOOKS_DIR="/var/ocr4all/data/"\nIMAGE_SUBDIR="/PreProc/Gray/"' > nashi-config.py
#ENV FLASK_APP nashi
#ENV NASHI_SETTINGS /opt/OCR4all_Web/submodules/nashi/server/nashi-config.py
#ENV DATABASE_URL sqlite:////opt/OCR4all_Web/submodules/nashi/server/test.db

# Download maven project
RUN cd /var/lib/tomcat8/webapps && \
    wget $ARTIFACTORY_URL/OCR4all_Web/$OCR4ALL_VERSION/OCR4all_Web-$OCR4ALL_VERSION.war -O OCR4all_Web.war && \
    wget $ARTIFACTORY_URL/GTC_Web/$GTCWEB_VERSION/GTC_Web-$GTCWEB_VERSION.war -O GTC_Web.war && \
    wget $ARTIFACTORY_URL/Larex/$LAREX_VERSION/Larex-$LAREX_VERSION.war -O Larex.war

#DEBUG TODO:REMOVE and update Versions
#COPY OCR4all_Web.war /var/lib/tomcat8/webapps/OCR4all_Web.war
#COPY GTC_Web.war /var/lib/tomcat8/webapps/GTC_Web.war

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

# Create index.html for calling url without tool url part!
COPY index.html /usr/share/tomcat8/webapps/ROOT/index.html

# Copy larex.config
COPY larex.config /larex.config
ENV LAREX_CONFIG=/larex.config

# Start processes when container is started
ENTRYPOINT [ "/usr/bin/supervisord" ]
