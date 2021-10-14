FROM ghcr.io/jogasser/gobra:${image_version}

COPY entrypoint.sh /gobra/entrypoint.sh
COPY verifyPackages.sh /gobra/verifyPackages.sh

RUN chmod +x /gobra/entrypoint.sh && chmod +x /gobra/verifyPackages.sh

WORKDIR /gobra

ENTRYPOINT ["/gobra/entrypoint.sh"]
