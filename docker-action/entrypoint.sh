#!/bin/bash

DEBUG_MODE=0

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
	cd -- "$LOCATION" || exit 1
	# the tail of the list of arguments (i.e., the args without
	# the function name and the first argument (LOCATION) are
	# the list of paths to be processed.
	echo "${@:2}" | xargs realpath | tr '\n' ' '
)

GOBRA_JAR="/gobra/gobra.jar"
JAVA_ARGS="-Xss$INPUT_JAVAXSS -Xmx$INPUT_JAVAXMX -XX:-UseContainerSupport -Dcom.sun.management.jmxremote=false -jar $GOBRA_JAR"

# the directory in which `actions/checkout` places the repository
REPOSITORY_ROOT="$GITHUB_WORKSPACE/$REPOSITORY_NAME"

if [[ $INPUT_PROJECTLOCATION ]]; then
	PROJECT_LOCATION="$GITHUB_WORKSPACE/$INPUT_PROJECTLOCATION"
else
	PROJECT_LOCATION="$REPOSITORY_ROOT"
fi

GOBRA_ARGS=""


if [[ $INPUT_VIPERBACKEND ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --backend $INPUT_VIPERBACKEND"
fi

if [[ $INPUT_CHOP ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --chop $INPUT_CHOP"
fi

if [[ $INPUT_RECURSIVE -eq 1 ]]; then
	GOBRA_ARGS="--recursive --projectRoot $PROJECT_LOCATION $GOBRA_ARGS"
fi

if [[ $INPUT_RESPECTFUNCTIONPREPERMAMOUNTS == "1" ]]; then
	GOBRA_ARGS="--respectFunctionPrePermAmounts $GOBRA_ARGS"
elif [[ $INPUT_RESPECTFUNCTIONPREPERMAMOUNTS == "0" ]]; then
	GOBRA_ARGS="--norespectFunctionPrePermAmounts $GOBRA_ARGS"
elif [[ $INPUT_RESPECTFUNCTIONPREPERMAMOUNTS ]]; then
	echo -e "${RED}The input 'respectFunctionPrePermAmounts' must be either 0 or 1 but was '$INPUT_RESPECTFUNCTIONPREPERMAMOUNTS'${RESET}"
	exit 1
fi

if [[ $INPUT_FILES ]]; then
	# shellcheck disable=SC2086 # the input is a space-separated list of paths and must be split
	RESOLVED_PATHS="$(getFileListInDir "$PROJECT_LOCATION" $INPUT_FILES)"
	echo "[DEBUG] Project Location: $PROJECT_LOCATION" > $DEBUG_OUT
	echo "[DEBUG] Input Files: $INPUT_FILES" > $DEBUG_OUT
	echo "[DEBUG] Resolved Paths: $RESOLVED_PATHS" > $DEBUG_OUT
	GOBRA_ARGS="-i $RESOLVED_PATHS $GOBRA_ARGS"
fi

if [[ $INPUT_PACKAGES ]]; then
	# INPUT_PACKAGES are paths to packages
	# shellcheck disable=SC2086 # the input is a space-separated list of paths and must be split
	RESOLVED_PATHS="$(getFileListInDir "$PROJECT_LOCATION" $INPUT_PACKAGES)"
	GOBRA_ARGS="-p $RESOLVED_PATHS $GOBRA_ARGS"
fi

if [[ $INPUT_INCLUDEPATHS ]]; then
	# shellcheck disable=SC2086 # the input is a space-separated list of paths and must be split
	RESOLVED_PATHS=$(getFileListInDir "$PROJECT_LOCATION" $INPUT_INCLUDEPATHS)
	echo "[DEBUG] Project Location: $PROJECT_LOCATION" > $DEBUG_OUT
	echo "[DEBUG] Include Paths: $INPUT_INCLUDEPATHS" > $DEBUG_OUT
	echo "[DEBUG] Resolved Paths: $RESOLVED_PATHS" > $DEBUG_OUT
	GOBRA_ARGS="$GOBRA_ARGS -I $RESOLVED_PATHS"
elif [[ ! $INPUT_CONFIGFILE ]]; then
	# not a default of Gobra: without it, imports of the project would not resolve
	GOBRA_ARGS="$GOBRA_ARGS -I $PROJECT_LOCATION"
fi

if [[ $INPUT_CACHING -eq 1 ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --cacheFile .gobra/cache.json"
fi

if [[ $INPUT_USEZ3API -eq 1 ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --z3APIMode"
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

# We are explicitely skipping the usage of Gobra's package timeout, given that it
# is currently very unreliable
# if [[ $INPUT_PACKAGETIMEOUT ]]; then
#    GOBRA_ARGS="$GOBRA_ARGS --packageTimeout $INPUT_PACKAGETIMEOUT"
# fi

if [[ $INPUT_ASSUMEINJECTIVITYONINHALE == "1" ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --assumeInjectivityOnInhale"
elif [[ $INPUT_ASSUMEINJECTIVITYONINHALE == "0" ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --noassumeInjectivityOnInhale"
elif [[ $INPUT_ASSUMEINJECTIVITYONINHALE ]]; then
	echo -e "${RED}The input 'assumeInjectivityOnInhale' must be either 0 or 1 but was '$INPUT_ASSUMEINJECTIVITYONINHALE'${RESET}"
	exit 1
fi

if [[ $INPUT_CHECKCONSISTENCY -eq 1 ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --checkConsistency"
fi

if [[ $INPUT_MCEMODE ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --mceMode=$INPUT_MCEMODE"
fi

if [[ $INPUT_PARALLELIZEBRANCHES -eq 1 ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --parallelizeBranches"
fi

if [[ $INPUT_REQUIRETRIGGERS -eq 1 ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --requireTriggers"
fi

if [[ $INPUT_ENABLEFRIENDCLAUSES -eq 1 ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --experimentalFriendClauses"
fi

if [[ $INPUT_DISABLENL -eq 1 ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --disableNL"
fi

if [[ $INPUT_UNSAFEWILDCARDOPTIMIZATION -eq 1 ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --unsafeWildcardOptimization"
fi

if [[ $INPUT_CONDITIONALIZEPERMISSIONS -eq 1 ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --conditionalizePermissions"
fi

if [[ $INPUT_MOREJOINS ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --moreJoins $INPUT_MOREJOINS"
fi

if [[ $INPUT_OVERFLOW -eq 1 ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --overflow"
fi

# In config file mode, `-g` is added to the JSON config further below instead, since it
# must not be passed on the command line next to `--config`.
if [[ $INPUT_STATSFILE && ! $INPUT_CONFIGFILE ]]; then
	# We write the file to /tmp/ (which is easier then making gobra write directly
	# to the STATS_TARGET, as doing so often causes Gobra to not generate a file) due
	# to the lack of permissions. We later move this file to correct destination.
	echo "[DEBUG] path to stats file was passed" > $DEBUG_OUT
	GOBRA_ARGS="$GOBRA_ARGS -g /tmp/"
else
	echo "[DEBUG] path to stats file was NOT passed" > $DEBUG_OUT
fi

if [[ $INPUT_CONFIGFILE ]]; then
	# Config file mode. Gobra reads all of its options from `gobra.json` and `gobra-mod.json`.
	# `--config` must not be combined with any other option of Gobra (except for `--printConfig`),
	# which Gobra itself reports as an error for every option that is explicitly passed above.
	# `caching` therefore reports an error: Gobra has no JSON field for `--cacheFile` yet.

	# `configFile` is relative to the directory in which the repository is checked out.
	# A leading '/' is stripped, i.e. an absolute path is treated as relative to it as well.
	CONFIG_PATH="$REPOSITORY_ROOT/${INPUT_CONFIGFILE#/}"
	echo "[DEBUG] Config Path: $CONFIG_PATH" > $DEBUG_OUT

	# `-g` has no dedicated field in the JSON config and cannot be passed on the command
	# line next to `--config`, so it is added to the `other` field of a generated copy of
	# the job config. The copy is placed next to the original, so that the relative paths
	# within it and the lookup of `gobra-mod.json` resolve as they do for the original.
	if [[ -f $CONFIG_PATH ]]; then
		JOB_CONFIG="$CONFIG_PATH"
		CONFIG_DIR=$(dirname "$CONFIG_PATH")
	else
		JOB_CONFIG="$CONFIG_PATH/gobra.json"
		CONFIG_DIR="$CONFIG_PATH"
	fi

	BASE_CONFIG='{}'
	if [[ -f $JOB_CONFIG ]]; then
		BASE_CONFIG=$(cat "$JOB_CONFIG")
	fi

	# A `-g` in the job config itself takes precedence, also because the option appearing
	# twice within the same `other` field would make Gobra reject it. A `-g` in the module
	# config is overruled, since the job config takes precedence over it in Gobra.
	if [[ $INPUT_STATSFILE ]] && ! jq -e '(.other // []) | any(. == "-g" or . == "--gobraDirectory")' <<< "$BASE_CONFIG" > /dev/null; then
		GENERATED_CONFIG="$CONFIG_DIR/.gobra-action-generated.json"
		# the generated config must not outlive this run, as it is written into the workspace
		trap 'rm -f "$GENERATED_CONFIG"' EXIT
		if ! jq '.other = ((.other // []) + ["-g", "/tmp/"])' <<< "$BASE_CONFIG" > "$GENERATED_CONFIG"; then
			echo -e "${RED}Failed to add the stats file option to the JSON config${RESET}"
			exit 1
		fi
		echo "[DEBUG] Generated config: $(cat "$GENERATED_CONFIG")" > $DEBUG_OUT
		CONFIG_PATH="$GENERATED_CONFIG"
	fi

	GOBRA_ARGS="$GOBRA_ARGS --config $CONFIG_PATH"
fi

# Gobra reports an error if this is used without `--config`
if [[ $INPUT_PRINTCONFIG -eq 1 ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --printConfig"
fi

START_TIME=$SECONDS
EXIT_CODE=0

CMD="java $JAVA_ARGS $GOBRA_ARGS"

echo "$CMD"

# shellcheck disable=SC2086 # the command is assembled as a string and must be split into arguments
timeout "$INPUT_TIMEOUT" $CMD
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
	echo -e "${GREEN}Verification completed successfully${RESET}"
	# if verification succeeded and the user expects a stats file, then
	# put it in the expected place
	if [[ $INPUT_STATSFILE ]]; then
		if [[ -f /tmp/stats.json ]]; then
			mv /tmp/stats.json "$STATS_TARGET"
		else
			echo -e "${YELLOW}Warning: Gobra did not generate a stats file${RESET}"
		fi
	fi
else
	if [ $EXIT_CODE -eq 124 ]; then
		echo ""
		echo -e "${RED}Verification job timed out${RESET}"
	else
		echo -e "${RED}There are verification errors${RESET}"
	fi
fi

TIME_PASSED=$(( SECONDS - START_TIME ))

echo "time=$TIME_PASSED" >> "$GITHUB_OUTPUT"

echo "[DEBUG] Contents of /tmp/:" > $DEBUG_OUT
ls -la /tmp/ > $DEBUG_OUT
echo "[DEBUG] Contents of /gobra/:" > $DEBUG_OUT
ls -la /gobra/ > $DEBUG_OUT
echo "[DEBUG] Contents of $STATS_TARGET:" > $DEBUG_OUT
ls -la "$STATS_TARGET" > $DEBUG_OUT

exit $EXIT_CODE
