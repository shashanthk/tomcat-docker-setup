FROM eclipse-temurin:21-jre-alpine

# Set environment variables
ENV CATALINA_HOME=/usr/local/tomcat
ENV PATH="$CATALINA_HOME/bin:$PATH"
ARG TOMCAT_ERROR_PAGE=/var/www/tomcat-error/

COPY ./apache-tomcat-10.1.36 /usr/local/tomcat/
COPY ./error_pages ${TOMCAT_ERROR_PAGE}

# Define Tomcat version and checksum
ARG TOMCAT_VERSION=10.1.36
ARG TOMCAT_SHA512=972a406263fd540b135efae4b375543781b26104acb07114c3e535fe31e5b0a5c87ae6dff055e0e47877a3861070c264bb236686cf08bc08d98b7541e5d743c7

# Create a dedicated non-root Tomcat user (fixed UID/GID for consistency)
ARG USER_NAME=tomcat
ARG GROUP_NAME=tomcat
ARG USER_ID=1000
ARG GROUP_ID=1000

RUN addgroup -S -g ${GROUP_ID} ${GROUP_NAME} \
    && adduser -S -G ${GROUP_NAME} -u ${USER_ID} -h ${CATALINA_HOME} -s /sbin/nologin ${USER_NAME} \
    && chown -R ${USER_NAME}:${GROUP_NAME} ${CATALINA_HOME} \
    && chown -R ${USER_NAME}:${GROUP_NAME} ${TOMCAT_ERROR_PAGE}

# Switch to non-root user
USER ${USER_NAME}

WORKDIR ${CATALINA_HOME}

# Expose Tomcat HTTP port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
