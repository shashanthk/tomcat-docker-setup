# Use a minimal base image
FROM eclipse-temurin:21-jdk-alpine AS builder

# Set environment variables
ENV CATALINA_HOME=/usr/local/tomcat
ENV PATH="$CATALINA_HOME/bin:$PATH"

# Define Tomcat version and checksum
ARG TOMCAT_VERSION=10.1.36
ARG TOMCAT_SHA512=972a406263fd540b135efae4b375543781b26104acb07114c3e535fe31e5b0a5c87ae6dff055e0e47877a3861070c264bb236686cf08bc08d98b7541e5d743c7

# Install only necessary packages and remove cache afterward to reduce image size
RUN apk add --no-cache wget tar \
    && wget "https://dlcdn.apache.org/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" \
    && echo "${TOMCAT_SHA512}  apache-tomcat-${TOMCAT_VERSION}.tar.gz" | sha512sum -c - \
    && mkdir -p ${CATALINA_HOME} \
    && tar --no-same-owner --no-same-permissions -xzf apache-tomcat-${TOMCAT_VERSION}.tar.gz -C ${CATALINA_HOME} --strip-components=1 \
    && rm -rf ${CATALINA_HOME}/webapps/{examples,docs} \
    && rm apache-tomcat-${TOMCAT_VERSION}.tar.gz

# Create a new lightweight image for running Tomcat
FROM eclipse-temurin:21-jdk-alpine

# Set environment variables again in the final image
ENV CATALINA_HOME=/usr/local/tomcat
ENV PATH="$CATALINA_HOME/bin:$PATH"

# Create a non-root Tomcat user (use fixed UID/GID for consistency)
ARG USER_NAME=tomcat
ARG GROUP_NAME=tomcat
ARG USER_ID=1000
ARG GROUP_ID=1000

RUN addgroup -S -g ${GROUP_ID} ${GROUP_NAME} \
    && adduser -S -G ${GROUP_NAME} -u ${USER_ID} -h ${CATALINA_HOME} -s /sbin/nologin ${USER_NAME}

# Copy only the necessary files from the builder stage
COPY --from=builder --chown=${USER_NAME}:${GROUP_NAME} ${CATALINA_HOME} ${CATALINA_HOME}

# Switch to non-root user
USER ${USER_NAME}

# Expose Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
