#!/bin/bash

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export RESET='\033[0m' # No Color
export PROJECT_LOCATION="$GITHUB_WORKSPACE/$INPUT_PROJECTLOCATION"
export PACKAGE_LOCATION="$PROJECT_LOCATION/$INPUT_PACKAGELOCATION"
export GOBRA_JAR="/gobra/gobra.jar"

START_TIME=$SECONDS

if [ -n "$INPUT_PACKAGES" ]; then
    export PACKAGES=$(echo -e $INPUT_PACKAGES | tr " " "\n" | sed  "s#.*#$PACKAGE_LOCATION/&#")
else
    export PACKAGES=$(find $PACKAGE_LOCATION -type d)
fi

EXIT_CODE=0

if timeout "$INPUT_GLOBALTIMEOUT" ./verifyPackages.sh; then
    echo -e "${GREEN}Verification completed successfully in${RESET}"
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
echo "::set-output name=numberOfMethods::0"
echo "::set-output name=numberOfAssumptions::0"
echo "::set-output name=numberOfDependingMethods::0"

exit $EXIT_CODE
