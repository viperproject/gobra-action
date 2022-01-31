#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m' # No Color

REPOSITORY_NAME=$(echo "$GITHUB_REPOSITORY" | awk -F / '{print $2}' | sed -e "s/:refs//")

PROJECT_LOCATION="$GITHUB_WORKSPACE/$REPOSITORY_NAME"

if [ -n $INPUT_PROJECTLOCATION ]; then
    GOBRAINPUT_LOCATION="$PROJECT_LOCATION/$INPUT_PROJECTLOCATION"
else
    GOBRAINPUT_LOCATION="$PROJECT_LOCATION"
fi

cd $PROJECT_LOCATION

PACKAGE_LOCATION="$PROJECT_LOCATION/$INPUT_PACKAGELOCATION"
GOBRA_JAR="/gobra/gobra.jar"

echo "Verification for project in $PROJECT_LOCATION started"
echo "Verifying packages located in $PACKAGE_LOCATION"

JAVA_ARGS="-Xss$INPUT_JAVAXSS -Xmx$INPUT_JAVAXMX -jar $GOBRA_JAR"
GOBRA_ARGS="-i $GOBRAINPUT_LOCATION --backend $INPUT_VIPERBACKEND "

if [ -n $INPUT_PACKAGEDIRECTORIES ]; then
    GOBRA_ARGS="$GOBRA_ARGS -I $INPUT_PACKAGEDIRECTORIES"
fi

if [ $INPUT_CACHING -eq 1 ]; then
    GOBRA_ARGS="$GOBRA_ARGS --cacheFile .gobra/cache.json"
fi

if [ -n $INPUT_PACKAGES ]; then
    GOBRA_ARGS="$GOBRA_ARGS -p $INPUT_PACKAGES"
fi

START_TIME=$SECONDS
EXIT_CODE=0

$CMD="java $JAVA_ARGS $GOBRA_ARGS"

if timeout "$INPUT_GLOBALTIMEOUT" $CMD; then
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

NUMBER_OF_PACKAGES_VERIFIED=$(cat output_num_packages)
NUMBER_OF_FAILED_PACKAGE_VERIFICATIONS=$(cat output_num_failed_packages)
NUMBER_OF_TIMEOUT_PACKAGE_VERIFICATIONS=$(cat output_num_timeout_packages)

echo "::set-output name=time::$TIME_PASSED"
echo "::set-output name=numberOfPackages::$NUMBER_OF_PACKAGES_VERIFIED"
echo "::set-output name=numberOfFailedPackages::$NUMBER_OF_FAILED_PACKAGE_VERIFICATIONS"
echo "::set-output name=numberOfTimedoutPackages::$NUMBER_OF_TIMEOUT_PACKAGE_VERIFICATIONS"
echo "::set-output name=numberOfMethods::0" # TODO: implement
echo "::set-output name=numberOfAssumptions::0" # TODO: implement
echo "::set-output name=numberOfDependingMethods::0" # TODO: implement

exit $EXIT_CODE
