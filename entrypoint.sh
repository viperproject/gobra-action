#!/bin/sh

echo "Creating a docker image with Gobra image tag: $INPUT_IMAGEVERSION"
docker build -t docker-action --build-arg image_version="$INPUT_IMAGEVERSION" /docker-action

echo "Run Docker Action container"
docker run -e INPUT_CACHING -e INPUT_PROJECTLOCATION -e INPUT_PACKAGELOCATION -e INPUT_PACKAGES -e INPUT_JAVAXSS -e INPUT_JAVAXMX -e INPUT_GLOBALTIMEOUT -e INPUT_PACKAGETIMEOUT \
  -v $GITHUB_WORKSPACE:$GITHUB_WORKSPACE \
  --workdir $GITHUB_WORKSPACE docker-action

