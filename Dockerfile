# Use Eclipse Temurin 21 JRE Alpine as the base image for a lightweight runtime environment.
FROM eclipse-temurin:21-jre-alpine

# Set environment variables for Tomcat's home directory and add its bin directory to the PATH.
ENV CATALINA_HOME=/usr/local/tomcat
ENV PATH="$CATALINA_HOME/bin:$PATH"

# Define an argument for the custom Tomcat error page directory.
ARG TOMCAT_ERROR_PAGE=/var/www/tomcat-error/

# Copy the pre-built Apache Tomcat distribution into the container.
COPY ./apache-tomcat-10.1.36 /usr/local/tomcat/

# Copy custom error pages into the specified directory.
COPY ./error_pages ${TOMCAT_ERROR_PAGE}

# Define build arguments for the Tomcat user and group, ensuring consistent UID/GID.
ARG USER_NAME=tomcat
ARG GROUP_NAME=tomcat
ARG USER_ID=1000
ARG GROUP_ID=1000

# Create a dedicated non-root user and group for running Tomcat, and set correct ownership.
RUN addgroup -S -g ${GROUP_ID} ${GROUP_NAME} \
    && adduser -S -G ${GROUP_NAME} -u ${USER_ID} -h ${CATALINA_HOME} -s /sbin/nologin ${USER_NAME} \
    && chown -R ${USER_NAME}:${GROUP_NAME} ${CATALINA_HOME} \
    && chown -R ${USER_NAME}:${GROUP_NAME} ${TOMCAT_ERROR_PAGE}

# Switch to the non-root Tomcat user for improved security.
USER ${USER_NAME}

# Set the working directory to Tomcat's home.
WORKDIR ${CATALINA_HOME}

# Expose Tomcat's default HTTP port.
EXPOSE 8080

# Start Tomcat using the catalina.sh script in the foreground.
CMD ["catalina.sh", "run"]
