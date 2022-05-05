#!/bin/bash

DEBUG_MODE=1

if [[ $DEBUG_MODE -eq 1 ]]; then
    DEBUG_OUT="/dev/stdout"
else
    DEBUG_OUT="/dev/nil"
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m' # No Color

echo "[DEBUG] Github Workspace: $GITHUB_WORKSPACE" > $DEBUG_OUT
REPOSITORY_NAME=$(echo "$GITHUB_REPOSITORY" | awk -F / '{print $2}' | sed -e "s/:refs//")

# returns the absolute path from a base path ($1) and a list of paths relative
# to the base path (${@:2}). Also works if one of the argument paths is an
# absolute path. Note: does not handle paths that contain a space.
getFileListInDir () (
    local LOCATION=$1
    cd -- "$LOCATION"
    # the tail of the list of arguments (i.e., the args without
    # the function name and the first argument (LOCATION) are
    # the list of paths to be processed.
    echo "$(echo "${@:2}" | xargs realpath | tr '\n' ' ')"
)

if [[ $INPUT_PROJECTLOCATION ]]; then
    PROJECT_LOCATION="$GITHUB_WORKSPACE/$REPOSITORY_NAME/$INPUT_PROJECTLOCATION"
else
    PROJECT_LOCATION="$GITHUB_WORKSPACE/$REPOSITORY_NAME"
fi

GOBRA_JAR="/gobra/gobra.jar"
JAVA_ARGS="-Xss$INPUT_JAVAXSS -Xmx$INPUT_JAVAXMX -jar $GOBRA_JAR"
GOBRA_ARGS="--backend $INPUT_VIPERBACKEND --chop $INPUT_CHOP"

if [[ $INPUT_RECURSIVE -eq 1 ]]; then
    GOBRA_ARGS="--recursive $GOBRA_ARGS"
fi

if [[ $INPUT_FILES ]]; then
    RESOLVED_PATHS="$(getFileListInDir $PROJECT_LOCATION $INPUT_FILES)"
    echo "[DEBUG] Project Location: $PROJECT_LOCATION" > $DEBUG_OUT
    echo "[DEBUG] Input Files: $INPUT_FILES" > $DEBUG_OUT
    echo "[DEBUG] Resolved Paths: $RESOLVED_PATHS" > $DEBUG_OUT
    GOBRA_ARGS="-i $RESOLVED_PATHS $GOBRA_ARGS"
fi

if [[ $INPUT_PACKAGES ]]; then
    if [[ $INPUT_RECURSIVE -eq 1 ]]; then
        # If in recursive mode, INPUT_PACKAGES are package names
        GOBRA_ARGS="-p $INPUT_PACKAGES $GOBRA_ARGS"
    else
        # If not in recursive mode, INPUT_PACKAGES are the paths to
        # the packages
        RESOLVED_PATHS="$(getFileListInDir $PROJECT_LOCATION $INPUT_PACKAGES)"
        GOBRA_ARGS="-p $RESOLVED_PATHS $GOBRA_ARGS"
    fi
fi

if [[ $INPUT_INCLUDEPATHS ]]; then
    RESOLVED_PATHS=$(getFileListInDir $PROJECT_LOCATION $INPUT_INCLUDEPATHS)
    echo "[DEBUG] Project Location: $PROJECT_LOCATION" > $DEBUG_OUT
    echo "[DEBUG] Include Paths: $INPUT_INCLUDEPATHS" > $DEBUG_OUT
    echo "[DEBUG] Resolved Paths: $RESOLVED_PATHS" > $DEBUG_OUT
    GOBRA_ARGS="$GOBRA_ARGS -I $RESOLVED_PATHS"
else
    GOBRA_ARGS="$GOBRA_ARGS -I $PROJECT_LOCATION" 
fi

if [[ $INPUT_CACHING -eq 1 ]]; then
    GOBRA_ARGS="$GOBRA_ARGS --cacheFile .gobra/cache.json"
fi

if [[ $INPUT_HEADERONLY -eq 1 ]]; then
    GOBRA_ARGS="$GOBRA_ARGS --onlyFilesWithHeader"
fi

if [[ $INPUT_MODULE ]]; then
    GOBRA_ARGS="$GOBRA_ARGS -m $INPUT_MODULE"
fi

if [[ $INPUT_EXCLUDEPACKAGES ]]; then
    GOBRA_ARGS="$GOBRA_ARGS --excludePackages $INPUT_EXCLUDEPACKAGES"
fi

if [[ $INPUT_PACKAGETIMEOUT ]]; then
    GOBRA_ARGS="$GOBRA_ARGS --packageTimeout $INPUT_PACKAGETIMEOUT"
fi

# The default mode in Gobra might change in the future.
# Having both options explicitly avoids subtle changes of
# behaviour if that happens.
if [[ $INPUT_ASSUMEINJECTIVITYONINHALE -eq 1 ]]; then
    GOBRA_ARGS="$GOBRA_ARGS --assumeInjectivityOnInhale"
else
    GOBRA_ARGS="$GOBRA_ARGS --noassumeInjectivityOnInhale"
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