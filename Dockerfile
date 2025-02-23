# --- Build Stage ---
FROM eclipse-temurin:21-jdk-alpine AS builder

# Set environment variables
ENV CATALINA_HOME=/usr/local/tomcat
ENV PATH="$CATALINA_HOME/bin:$PATH"

# Define Tomcat version and checksum
ARG TOMCAT_VERSION=10.1.36
ARG TOMCAT_SHA512=972a406263fd540b135efae4b375543781b26104acb07114c3e535fe31e5b0a5c87ae6dff055e0e47877a3861070c264bb236686cf08bc08d98b7541e5d743c7

# Install required packages, download Tomcat, verify checksum, extract, and clean up in one step
RUN apk add --no-cache wget tar \
    && wget -q "https://dlcdn.apache.org/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" -O /tmp/tomcat.tar.gz \
    && echo "${TOMCAT_SHA512}  /tmp/tomcat.tar.gz" | sha512sum -c - \
    && mkdir -p ${CATALINA_HOME} \
    && tar --no-same-owner --no-same-permissions -xzf /tmp/tomcat.tar.gz -C ${CATALINA_HOME} --strip-components=1 \
    && rm -rf /tmp/tomcat.tar.gz \
    && rm -rf ${CATALINA_HOME}/webapps/{examples,docs}

# Create a dedicated non-root Tomcat user (fixed UID/GID for consistency)
ARG USER_NAME=tomcat
ARG GROUP_NAME=tomcat
ARG USER_ID=1000
ARG GROUP_ID=1000

RUN addgroup -S -g ${GROUP_ID} ${GROUP_NAME} \
    && adduser -S -G ${GROUP_NAME} -u ${USER_ID} -h ${CATALINA_HOME} -s /sbin/nologin ${USER_NAME} \
    && chown -R ${USER_NAME}:${GROUP_NAME} ${CATALINA_HOME}

# Copy custom configuration and error pages
COPY --chown=${USER_NAME}:${GROUP_NAME} error_pages/* ${CATALINA_HOME}/webapps/ROOT/
COPY --chown=${USER_NAME}:${GROUP_NAME} config/server.xml ${CATALINA_HOME}/conf/server.xml

# Set error page directory in catalina.properties
RUN echo "error.page.dir=\${catalina.home}/webapps/ROOT/" >> ${CATALINA_HOME}/conf/catalina.properties

# --- Final Image ---
FROM eclipse-temurin:21-jdk-alpine

# Set environment variables again
ENV CATALINA_HOME=/usr/local/tomcat
ENV PATH="$CATALINA_HOME/bin:$PATH"

# Create a non-root Tomcat user (use same UID/GID as builder)
ARG USER_NAME=tomcat
ARG GROUP_NAME=tomcat
ARG USER_ID=1000
ARG GROUP_ID=1000

RUN addgroup -S -g ${GROUP_ID} ${GROUP_NAME} \
    && adduser -S -G ${GROUP_NAME} -u ${USER_ID} -h ${CATALINA_HOME} -s /sbin/nologin ${USER_NAME}

# Copy Tomcat installation from builder stage
COPY --from=builder --chown=${USER_NAME}:${GROUP_NAME} ${CATALINA_HOME} ${CATALINA_HOME}

# Switch to non-root user
USER ${USER_NAME}

# Expose Tomcat HTTP port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
