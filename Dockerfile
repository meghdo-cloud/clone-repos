FROM ubuntu:20.04

# Install dependencies including git
RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Download and install Google Cloud SDK
RUN curl -o /tmp/google-cloud-sdk.tar.gz https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz && \
    mkdir -p /usr/local/gcloud && \
    tar -C /usr/local/gcloud -xvf /tmp/google-cloud-sdk.tar.gz && \
    /usr/local/gcloud/google-cloud-sdk/install.sh --quiet

# Add gcloud to PATH
ENV PATH $PATH:/usr/local/gcloud/google-cloud-sdk/bin

# Clean up
RUN rm /tmp/google-cloud-sdk.tar.gz

# Copy the shell script into the container
COPY gitcopy.sh /app/gitcopy.sh

# Make the shell script executable
RUN chmod +x /app/gitcopy.sh



# Set environment variables
# These could also be passed in at runtime via Helm or kubectl
ENV GITHUB_TOKEN=""
ENV SOURCE_REPO=""
ENV GIT_ORG=""
ENV DNS=""
ENV PROJECT=""
ENV PROJECTID=""
ENV REGION=""
ENV GROUP=""
ENV DIRECTORY=""

# Entry point to run the script
ENTRYPOINT ["/bin/bash", "/app/gitcopy.sh"]
