# Use Debian Bullseye as the base image
FROM debian:bullseye

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Define build argument for SignalWire token
ARG SIGNALWIRE_TOKEN

# Install dependencies and set up SignalWire repository
RUN apt-get update && apt-get install -yq gnupg2 wget lsb-release git \
    && wget --http-user=signalwire --http-password=${SIGNALWIRE_TOKEN} -O /usr/share/keyrings/signalwire-freeswitch-repo.gpg https://freeswitch.signalwire.com/repo/deb/debian-release/signalwire-freeswitch-repo.gpg \
    && echo "machine freeswitch.signalwire.com login signalwire password ${SIGNALWIRE_TOKEN}" > /etc/apt/auth.conf \
    && chmod 600 /etc/apt/auth.conf \
    && echo "deb [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/freeswitch.list \
    && echo "deb-src [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ $(lsb_release -sc) main" >> /etc/apt/sources.list.d/freeswitch.list \
    && apt-get update \
    && apt-get build-dep -y freeswitch

# Copy FreeSWITCH source code
COPY freeswitch-src /freeswitch-src

# Build and install FreeSWITCH
WORKDIR /freeswitch-src
RUN git config pull.rebase true \
    && ./bootstrap.sh -j \
    && ./configure \
    && make \
    && make install

# Set the working directory
WORKDIR /usr/local/freeswitch

# Expose necessary ports
EXPOSE 5060/udp 5060/tcp 5080/tcp 8021/tcp

# Start FreeSWITCH
CMD ["./bin/freeswitch", "-nonat", "-nc"]
