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

# Set the script permissions
RUN chmod +x gitcopy.sh

# The command that runs the shell script
ENTRYPOINT ["./gitcopy.sh"]
