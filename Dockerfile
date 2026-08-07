FROM alpine:latest

COPY docker-action /docker-action
COPY entrypoint.sh /entrypoint.sh
# `action.yml` is the single source of truth for the defaults of the inputs
COPY action.yml /action.yml
COPY defaults.awk /defaults.awk
RUN chmod +x /entrypoint.sh

RUN apk add --update --no-cache docker

ENTRYPOINT ["/entrypoint.sh"]
