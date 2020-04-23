FROM golang:1.11 as api-builder
WORKDIR /unoconv-api
COPY . /unoconv-api
RUN go build


FROM ubuntu:20.04

LABEL maintainer="kaufmann.r@gmail.com"

COPY --from=api-builder /unoconv-api/unoconv-api /opt/unoconv-api/unoconv-api

#Install unoconv and other deps
ENV DEBIAN_FRONTEND=noninteractive
RUN \
	apt-get update && \
	echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections && \
	echo "tzdata tzdata/Areas select Europe" | debconf-set-selections && \
	echo "tzdata tzdata/Zones/Europe select Berlin" | debconf-set-selections && \
	apt-get install -y \
	locales \
	unoconv \
	ttf-mscorefonts-installer \
	supervisor && \
	apt-get remove -y && \
	apt-get autoremove -y && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/

# Set the locale
RUN locale-gen en_GB.UTF-8
ENV LANG en_GB.UTF-8

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose 3000
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s \
	CMD curl http://localhost:3000/unoconv/health

# Startup
ENTRYPOINT ["/usr/bin/supervisord"]
