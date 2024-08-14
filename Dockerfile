FROM ubuntu:18.04

# Update and upgrade the base packages
RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get install -y curl gnupg apt-transport-https nginx-extras

# Add Tor repository and import the GPG key
RUN echo 'deb https://deb.torproject.org/torproject.org bionic main' >> /etc/apt/sources.list && \
    curl https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import && \
    gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -

# Install Tor and its keyring
RUN apt-get update && \
    apt-get install -y tor deb.torproject.org-keyring

# Configure Tor for the hidden service
RUN sed -i 's@#HiddenServiceDir /var/lib/tor/hidden_service/@HiddenServiceDir /var/lib/tor/hidden_service/@' /etc/tor/torrc && \
    sed -i 's@#HiddenServicePort 80 127.0.0.1:80@HiddenServicePort 80 127.0.0.1:80@' /etc/tor/torrc

# Clean up Nginx default configuration and setup log redirection
RUN rm -vf /etc/nginx/nginx.conf && \
    rm -vf /etc/nginx/sites-{available,enabled}/default && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Create directory for the hidden service and copy index.html file
RUN mkdir -p /var/www/hiddenservice
COPY index.html /var/www/hiddenservice/index.html
COPY error.html /val/www/hiddenservice/error.html

# Define volumes for the hidden service content
VOLUME /var/www/hiddenservice

# Copy the Nginx configuration files and entrypoint script
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/hiddenservice.conf /etc/nginx/sites-available/hiddenservice.conf
COPY entrypoint.sh /entrypoint.sh

# Make sure the entrypoint script is executable
RUN chmod +x /entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]
