ARG image_version=latest
ARG image_name=ghcr.io/viperproject/gobra

FROM ${image_name}:${image_version}


COPY entrypoint.sh /gobra/entrypoint.sh

RUN chmod +x /gobra/entrypoint.sh

RUN add-apt-repository ppa:longsleep/golang-backports
RUN apt-get update && \
	apt-get install -y \
	libz3-java \
	golang-go \
	git


WORKDIR /gobra

RUN git clone https://github.com/jcp19/gobrago.git
RUN cd gobrago && \
	go build . && \
	mv gobrago ~/.local/bin


ENTRYPOINT ["/gobra/entrypoint.sh"]

