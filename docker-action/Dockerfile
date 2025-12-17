ARG image_version=latest
ARG image_name=ghcr.io/viperproject/gobra

FROM ${image_name}:${image_version}


COPY entrypoint.sh /gobra/entrypoint.sh

RUN chmod +x /gobra/entrypoint.sh

RUN apt-get update && \
	apt-get install -y \
	libz3-java \
	git \
	wget

# Install Go

RUN export GO_VERSION=1.22.6 && \
	wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
	tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz

ENV PATH=/usr/local/go/bin:$PATH

RUN go version

WORKDIR /gobra

RUN git clone https://github.com/jcp19/gobrago.git
RUN cd gobrago && \
	go build . && \
	mv gobrago ~/.local/bin


ENTRYPOINT ["/gobra/entrypoint.sh"]

