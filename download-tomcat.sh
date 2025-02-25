#!/bin/bash

# Define base URL for Apache Tomcat downloads
BASE_URL="https://downloads.apache.org/tomcat/tomcat-10/"

# Fetch the latest full version (major.minor.bug) dynamically
LATEST_VERSION=$(curl --silent $BASE_URL | grep v10 | awk '{split($5,c,">v") ; split(c[2],d,"/") ; print d[1]}' | sort -V | tail -1)

# Check if version was found
if [[ -z "$LATEST_VERSION" ]]; then
    echo "Error: Failed to fetch the latest Tomcat version."
    exit 1
fi

# Construct the full download URL
TOMCAT_ARCHIVE="apache-tomcat-${LATEST_VERSION}.tar.gz"
DOWNLOAD_URL="${BASE_URL}v${LATEST_VERSION}/bin/${TOMCAT_ARCHIVE}"

# Download Tomcat using curl
echo "Downloading Tomcat version ${LATEST_VERSION} from ${DOWNLOAD_URL}..."
curl -O ${DOWNLOAD_URL}

# Verify if the file was downloaded
if [[ ! -f "$TOMCAT_ARCHIVE" ]]; then
    echo "Error: Download failed or file not found."
    exit 1
fi

# Extract the downloaded archive
echo "Extracting ${TOMCAT_ARCHIVE}..."
tar -xzf ${TOMCAT_ARCHIVE}

# Define extracted directory name
TOMCAT_DIR="apache-tomcat-${LATEST_VERSION}"

# Confirm extraction
if [[ -d "$TOMCAT_DIR" ]]; then
    echo "Tomcat successfully extracted to ${TOMCAT_DIR}"

    # Delete tar file
    rm -r ${TOMCAT_ARCHIVE}
else
    echo "Error: Extraction failed."
    exit 1
fi
