FROM ubuntu:22.04

WORKDIR /app

RUN apt-get update && \
    apt-get install -y \
    libssl-dev \
    libevent-dev \
    zlib1g-dev \
    git \
    curl \
    xz-utils \
    gpg \
    build-essential \
    gcc \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsS https://dlang.org/install.sh | bash -s dmd

RUN echo '#!/bin/bash\n\
source ~/dlang/dmd-2.111.0/activate\n\
exec "$@"' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
COPY libs/ /app/libs/
CMD ["dub", "clean"] 
CMD ["dub", "run"] 