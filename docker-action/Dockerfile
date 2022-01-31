ARG image_version=latest
ARG image_name=ghcr.io/viperproject/gobra

FROM ${image_name}:${image_version}

COPY entrypoint.sh /gobra/entrypoint.sh

RUN chmod +x /gobra/entrypoint.sh

WORKDIR /gobra

ENTRYPOINT ["/gobra/entrypoint.sh"]
