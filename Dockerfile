ARG BASE_IMAGE_TAG=latest

FROM ocr4all-base

ARG OCR4LL_BRANCH=master
ARG LAREX_BRANCH=master
ARG OCR4ALL_HELPER_SCRIPTS_BRANCH=master

ENV OCR4ALL_VERSION="0.6.1"
ENV LAREX_VERSION="0.7.0"

# Install helper scripts to make all scripts available to JAVA environment
RUN git clone -b ${OCR4ALL_HELPER_SCRIPTS_BRANCH} https://github.com/OCR4all/OCR4all_helper-scripts /opt/OCR4all_helper-scripts
WORKDIR /opt/OCR4all_helper-scripts
RUN python3 -m pip install .

# Clone OCR4all and LAREX
RUN git clone --depth 1 --branch ${OCR4LL_BRANCH} https://github.com/OCR4all/OCR4all /tmp/OCR4all
RUN git clone --depth 1 --branch ${LAREX_BRANCH} https://github.com/OCR4all/LAREX /tmp/LAREX
# Build OCR4all and LAREX
WORKDIR /tmp/OCR4all
RUN mvn clean install -f pom.xml
RUN cp target/ocr4all.war /var/lib/tomcat9/webapps/.
WORKDIR /tmp/LAREX
RUN mvn clean install -f pom.xml
RUN cp target/Larex.war /var/lib/tomcat9/webapps/.

RUN rm -r /tmp/*

# Create index.html for calling url without tool url part!
COPY index.html /usr/share/tomcat/webapps/ROOT/index.html

# Copy larex.properties
COPY larex.properties /larex.properties
ENV LAREX_CONFIG=/larex.properties

# Add admin/admin user
COPY server.xml /usr/share/tomcat9/conf/server.xml

CMD ["/usr/share/tomcat9/bin/catalina.sh", "run"]