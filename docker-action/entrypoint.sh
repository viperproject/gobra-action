#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m' # No Color

REPOSITORY_NAME=$(echo "$GITHUB_REPOSITORY" | awk -F / '{print $2}' | sed -e "s/:refs//")

if [[ $INPUT_SRCDIRECTORY ]]; then
    GOBRAINPUT_LOCATION="$GITHUB_WORKSPACE/$INPUT_SRCDIRECTORY"
else
    GOBRAINPUT_LOCATION="$GITHUB_WORKSPACE/$REPOSITORY_NAME"
fi

GOBRA_JAR="/gobra/gobra.jar"

JAVA_ARGS="-Xss$INPUT_JAVAXSS -Xmx$INPUT_JAVAXMX -jar $GOBRA_JAR"
GOBRA_ARGS="-i $GOBRAINPUT_LOCATION -r --backend $INPUT_VIPERBACKEND --chop $INPUT_CHOP"

if [[ $INPUT_PACKAGEDIRECTORIES ]]; then
    GOBRA_ARGS="$GOBRA_ARGS -I $GITHUB_WORKSPACE/$INPUT_PACKAGEDIRECTORIES"
else
    GOBRA_ARGS="$GOBRA_ARGS -I $GITHUB_WORKSPACE/$INPUT_SRCDIRECTORY" 
fi

if [[ $INPUT_CACHING -eq 1 ]]; then
    GOBRA_ARGS="$GOBRA_ARGS --cacheFile .gobra/cache.json"
fi

if [[ $INPUT_PACKAGES ]]; then
    GOBRA_ARGS="$GOBRA_ARGS -p $INPUT_PACKAGES"
fi

if [[ $INPUT_EXCLUDEPACKAGES ]]; then
    GOBRA_ARGS="$GOBRA_ARGS --excludePackages $INPUT_EXCLUDEPACKAGES"
fi

START_TIME=$SECONDS
EXIT_CODE=0

CMD="java $JAVA_ARGS $GOBRA_ARGS"

echo $CMD

if timeout $INPUT_GLOBALTIMEOUT $CMD; then
    echo -e "${GREEN}Verification completed successfully${RESET}"
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
	echo -e "${RED}Verification timed out globally${RESET}"
    else
	echo -e "${RED}There are verification errors${RESET}"
    fi
fi

TIME_PASSED=$[ $SECONDS-$START_TIME ]

echo "::set-output name=time::$TIME_PASSED"

exit $EXIT_CODE
