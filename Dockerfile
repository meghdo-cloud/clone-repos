# Use an Alpine base image
FROM alpine:3.18

# Install necessary packages: git, curl, bash, and openssh for git access
RUN apk add --no-cache \
    bash \
    git \
    curl \
    openssh \
    sed \
    coreutils \
    findutils

# Create the working directory
WORKDIR /usr/src/app

# Copy the shell script into the container
COPY gitcopy.sh .

RUN dos2unix gitcopy.sh && \
    chmod +x gitcopy.sh && \
    # Verify the file exists and is executable
    ls -la gitcopy.sh

# The command that runs the shell script
ENTRYPOINT ["/bin/bash", "./gitcopy.sh"]
