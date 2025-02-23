# Use Eclipse Temurin OpenJDK 21 Alpine as the base image
FROM eclipse-temurin:21-jdk-alpine

# Install necessary packages
RUN apk update && apk add --no-cache wget tar

WORKDIR /tmp

# Set Tomcat environment variables
ENV CATALINA_HOME=/usr/local/tomcat
ENV PATH="$CATALINA_HOME/bin:$PATH"

# Define Tomcat version and checksum
ARG TOMCAT_VERSION=10.1.36
ARG TOMCAT_SHA512=972a406263fd540b135efae4b375543781b26104acb07114c3e535fe31e5b0a5c87ae6dff055e0e47877a3861070c264bb236686cf08bc08d98b7541e5d743c7

# Define Tomcat user and group
ARG USER_NAME=tomcat
ARG GROUP_NAME=tomcat

# Create Tomcat user and group
RUN addgroup -S ${GROUP_NAME} \
    && adduser -S -G ${GROUP_NAME} -h ${CATALINA_HOME} -s /sbin/nologin ${USER_NAME}

# Download Tomcat
RUN wget "https://dlcdn.apache.org/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" \
    && echo "${TOMCAT_SHA512}  apache-tomcat-${TOMCAT_VERSION}.tar.gz" | sha512sum -c -

# Extract Tomcat in a temporary directory first
RUN mkdir -p /tmp/tomcat \
    && tar --no-same-owner --no-same-permissions -xzf apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /tmp/tomcat \
    && mkdir -p ${CATALINA_HOME} \
    && mv /tmp/tomcat/apache-tomcat-${TOMCAT_VERSION}/* ${CATALINA_HOME}/ \
    && rm -rf /tmp/tomcat apache-tomcat-${TOMCAT_VERSION}.tar.gz \
    && rm -rf ${CATALINA_HOME}/webapps/examples \
    && rm -rf ${CATALINA_HOME}/webapps/docs

# Ensure the tomcat user has permissions
RUN chown -R ${USER_NAME}:${GROUP_NAME} ${CATALINA_HOME}

# Switch to non-root user
USER ${USER_NAME}

# Expose Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
