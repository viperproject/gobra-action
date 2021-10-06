FROM ghcr.io/jogasser/gobra:latest

COPY entrypoint.sh /gobra/entrypoint.sh
COPY verifyPackages.sh /gobra/verifyPackages.sh

RUN chmod +x /gobra/entrypoint.sh && chmod +x /gobra/verifyPackages.sh

WORKDIR /gobra

ENTRYPOINT ["/gobra/entrypoint.sh"]
