# Use the Swift base image
FROM swift:5.9

# Install necessary tools and libraries for C and inotify
RUN apt-get update && apt-get install -y \
    build-essential \
    libc6-dev \
    inotify-tools \
    gdb \
    clang-format && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the working directory inside the container
WORKDIR /app

# Copy your project folder into the container
COPY . /app

# Expose any ports if your application requires it (e.g., for gRPC)
# EXPOSE 8080

# Default command to start an interactive bash shell
CMD ["/bin/bash"]

