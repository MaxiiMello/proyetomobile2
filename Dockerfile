FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

ENV FLUTTER_HOME=/opt/flutter
ENV PATH=${FLUTTER_HOME}/bin:${PATH}

RUN git clone https://github.com/flutter/flutter.git -b stable ${FLUTTER_HOME}

RUN flutter config --enable-web

WORKDIR /app

EXPOSE 8080

CMD ["flutter", "run", "-d", "web-server", "--web-port", "8080", "--web-hostname", "0.0.0.0"]