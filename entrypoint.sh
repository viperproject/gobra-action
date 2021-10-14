#!/bin/sh

REPO_NAME=$(basename $RUNNER_WORKSPACE)
WS_PATH=$RUNNER_WORKSPACE/$REPO_NAME

echo "Creating a docker image with Gobra image tag: $INPUT_IMAGEVERSION"
docker build -t docker-action --build-arg "image_version=$INPUT_IMAGEVERSION" /docker-action

echo "Run Docker Action container"
docker run -e INPUT_CACHING -e INPUT_PROJECTLOCATION -e INPUT_PACKAGELOCATION -e INPUT_PACKAGES -e INPUT_JAVAXSS -e INPUT_JAVAXMX -e INPUT_GLOBALTIMEOUT -e INPUT_PACKAGETIMEOUT -e GITHUB_WORKSPACE -e GITHUB_REPOSITORY \
  -v $WS_PATH:$GITHUB_WORKSPACE \
  --workdir $GITHUB_WORKSPACE docker-action

