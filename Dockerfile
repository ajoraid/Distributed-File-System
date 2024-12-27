FROM swift:5.9
RUN apt-get update && apt-get install -y \
    build-essential \
    libc6-dev \
    inotify-tools \
    gdb \
    clang-format && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY . /app
CMD ["/bin/bash"]
