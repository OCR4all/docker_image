ARG BASE_IMAGE_TAG=dev

FROM uniwuezpd/ocr4all_base:$BASE_IMAGE_TAG

ARG OCR4LL_BRANCH=dev
ARG LAREX_BRANCH=dev
ARG OCR4ALL_HELPER_SCRIPTS_BRANCH=master

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
RUN cp target/ocr4all.war /usr/local/tomcat/webapps/.
WORKDIR /tmp/LAREX
RUN mvn clean install -f pom.xml
RUN cp target/Larex.war /usr/local/tomcat/webapps/.

RUN rm -r /tmp/*

# Create index.html for calling url without tool url part!
COPY index.html /usr/share/tomcat/webapps/ROOT/index.html

# Copy larex.config
COPY larex.config /larex.config
ENV LAREX_CONFIG=/larex.config
