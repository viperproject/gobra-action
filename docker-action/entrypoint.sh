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
	cd -- "$LOCATION"
	# the tail of the list of arguments (i.e., the args without
	# the function name and the first argument (LOCATION) are
	# the list of paths to be processed.
	echo "$(echo "${@:2}" | xargs realpath | tr '\n' ' ')"
)

GOBRA_JAR="/gobra/gobra.jar"
JAVA_ARGS="-Xss$INPUT_JAVAXSS -Xmx$INPUT_JAVAXMX -XX:-UseContainerSupport -Dcom.sun.management.jmxremote=false -jar $GOBRA_JAR"

if [[ $INPUT_PROJECTLOCATION ]]; then
	PROJECT_LOCATION="$GITHUB_WORKSPACE/$INPUT_PROJECTLOCATION"
else
	PROJECT_LOCATION="$GITHUB_WORKSPACE/$REPOSITORY_NAME"
fi

# collects the names of the inputs that are ignored in config file mode
IGNORED_INPUTS=""

# records the input named $1 as ignored if its value ($2) differs from its default ($3)
recordIgnoredInput () {
	if [[ "$2" != "$3" ]]; then
		IGNORED_INPUTS="$IGNORED_INPUTS $1"
	fi
}

if [[ $INPUT_CONFIGFILE ]]; then

# Config file mode. Gobra reads all of its options from `gobra.json` and `gobra-mod.json`.
# `--config` must not be combined with any other option of Gobra (except for `--printConfig`),
# thus, none of the options derived from the remaining inputs are passed on.

# `configFile` is relative to the workflow context, just like `projectLocation`.
CONFIG_PATH="$GITHUB_WORKSPACE/$INPUT_CONFIGFILE"
echo "[DEBUG] Config Path: $CONFIG_PATH" > $DEBUG_OUT

if [[ ! -e $CONFIG_PATH ]]; then
	echo -e "${RED}The path provided in 'configFile' does not exist: $INPUT_CONFIGFILE${RESET}"
	echo "'configFile' is resolved relative to the workflow context, i.e. it usually starts with the name of the repository."
	exit 1
fi

# the input modes of Gobra are mutually exclusive
CONFLICTING_INPUTS=""
if [[ $INPUT_FILES ]]; then CONFLICTING_INPUTS="$CONFLICTING_INPUTS files"; fi
if [[ $INPUT_PACKAGES ]]; then CONFLICTING_INPUTS="$CONFLICTING_INPUTS packages"; fi
if [[ $INPUT_RECURSIVE -eq 1 ]]; then CONFLICTING_INPUTS="$CONFLICTING_INPUTS recursive"; fi
if [[ $CONFLICTING_INPUTS ]]; then
	echo -e "${RED}The input 'configFile' cannot be combined with:$CONFLICTING_INPUTS${RESET}"
	echo "In config file mode, the files or packages to verify are specified in the JSON config."
	exit 1
fi

# all remaining options of Gobra come from the JSON config, so point out the inputs that have no effect
recordIgnoredInput 'projectLocation' "$INPUT_PROJECTLOCATION" ''
recordIgnoredInput 'includePaths' "$INPUT_INCLUDEPATHS" ''
recordIgnoredInput 'excludePackages' "$INPUT_EXCLUDEPACKAGES" ''
recordIgnoredInput 'module' "$INPUT_MODULE" ''
recordIgnoredInput 'caching' "$INPUT_CACHING" '0'
recordIgnoredInput 'enableFriendClauses' "$INPUT_ENABLEFRIENDCLAUSES" '0'
recordIgnoredInput 'respectFunctionPrePermAmounts' "$INPUT_RESPECTFUNCTIONPREPERMAMOUNTS" '0'
recordIgnoredInput 'overflow' "$INPUT_OVERFLOW" '0'
recordIgnoredInput 'chop' "$INPUT_CHOP" '1'
recordIgnoredInput 'viperBackend' "$INPUT_VIPERBACKEND" 'SILICON'
recordIgnoredInput 'headerOnly' "$INPUT_HEADERONLY" '0'
recordIgnoredInput 'assumeInjectivityOnInhale' "$INPUT_ASSUMEINJECTIVITYONINHALE" '1'
recordIgnoredInput 'checkConsistency' "$INPUT_CHECKCONSISTENCY" '0'
recordIgnoredInput 'mceMode' "$INPUT_MCEMODE" 'on'
recordIgnoredInput 'parallelizeBranches' "$INPUT_PARALLELIZEBRANCHES" '0'
recordIgnoredInput 'requireTriggers' "$INPUT_REQUIRETRIGGERS" '0'
recordIgnoredInput 'conditionalizePermissions' "$INPUT_CONDITIONALIZEPERMISSIONS" '0'
recordIgnoredInput 'disableNL' "$INPUT_DISABLENL" '0'
recordIgnoredInput 'moreJoins' "$INPUT_MOREJOINS" 'off'
recordIgnoredInput 'unsafeWildcardOptimization' "$INPUT_UNSAFEWILDCARDOPTIMIZATION" '0'
recordIgnoredInput 'useZ3API' "$INPUT_USEZ3API" '0'

if [[ $IGNORED_INPUTS ]]; then
	echo -e "${YELLOW}Warning: the following inputs have no effect in config file mode:$IGNORED_INPUTS${RESET}"
	echo "In config file mode, all options of Gobra are read from 'gobra.json' and 'gobra-mod.json'."
	echo "Options without a dedicated field in the JSON config can be set via their 'other' field."
fi

GOBRA_ARGS="--config $CONFIG_PATH"

if [[ $INPUT_PRINTCONFIG -eq 1 ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --printConfig"
fi

else

# `printConfig` is only supported by Gobra in combination with `--config`
if [[ $INPUT_PRINTCONFIG -eq 1 ]]; then
	echo -e "${RED}The input 'printConfig' requires the input 'configFile' to be set.${RESET}"
	exit 1
fi

GOBRA_ARGS="--backend $INPUT_VIPERBACKEND --chop $INPUT_CHOP"

if [[ $INPUT_RECURSIVE -eq 1 ]]; then
	GOBRA_ARGS="--recursive --projectRoot $PROJECT_LOCATION $GOBRA_ARGS"
fi

if [[ $INPUT_RESPECTFUNCTIONPREPERMAMOUNTS -eq 1 ]]; then
	GOBRA_ARGS="--respectFunctionPrePermAmounts $GOBRA_ARGS"
else
	GOBRA_ARGS="--norespectFunctionPrePermAmounts $GOBRA_ARGS"
fi

if [[ $INPUT_FILES ]]; then
	RESOLVED_PATHS="$(getFileListInDir $PROJECT_LOCATION $INPUT_FILES)"
	echo "[DEBUG] Project Location: $PROJECT_LOCATION" > $DEBUG_OUT
	echo "[DEBUG] Input Files: $INPUT_FILES" > $DEBUG_OUT
	echo "[DEBUG] Resolved Paths: $RESOLVED_PATHS" > $DEBUG_OUT
	GOBRA_ARGS="-i $RESOLVED_PATHS $GOBRA_ARGS"
fi

if [[ $INPUT_PACKAGES ]]; then
	# INPUT_PACKAGES are paths to packages
	RESOLVED_PATHS="$(getFileListInDir $PROJECT_LOCATION $INPUT_PACKAGES)"
	GOBRA_ARGS="-p $RESOLVED_PATHS $GOBRA_ARGS"
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

# The default mode in Gobra might change in the future.
# Having both options explicitly avoids subtle changes of
# behaviour if that happens.
if [[ $INPUT_ASSUMEINJECTIVITYONINHALE -eq 1 ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --assumeInjectivityOnInhale"
else
	GOBRA_ARGS="$GOBRA_ARGS --noassumeInjectivityOnInhale"
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

GOBRA_ARGS="$GOBRA_ARGS --moreJoins $INPUT_MOREJOINS"

if [[ $INPUT_OVERFLOW -eq 1 ]]; then
	GOBRA_ARGS="$GOBRA_ARGS --overflow"
fi

if [[ $INPUT_STATSFILE ]]; then
	# We write the file to /tmp/ (which is easier then making gobra write directly
	# to the STATS_TARGET, as doing so often causes Gobra to not generate a file) due
	# to the lack of permissions. We later move this file to correct destination.
	echo "[DEBUG] path to stats file was passed" > $DEBUG_OUT
	GOBRA_ARGS="$GOBRA_ARGS -g /tmp/"
else
	echo "[DEBUG] path to stats file was NOT passed" > $DEBUG_OUT
fi

fi # end of the distinction between config file mode and the remaining input modes

START_TIME=$SECONDS
EXIT_CODE=0

CMD="java $JAVA_ARGS $GOBRA_ARGS"

echo $CMD

timeout $INPUT_TIMEOUT $CMD
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
	echo -e "${GREEN}Verification completed successfully${RESET}"
	# if verification succeeded and the user expects a stats file, then
	# put it in the expected place
	if [[ $INPUT_STATSFILE ]]; then
		if [[ -f /tmp/stats.json ]]; then
			mv /tmp/stats.json $STATS_TARGET
		else
			echo -e "${YELLOW}Warning: Gobra did not generate a stats file${RESET}"
			if [[ $INPUT_CONFIGFILE ]]; then
				echo "In config file mode, the stats file has to be requested in the JSON config, e.g. with \"other\": [\"-g\", \"/tmp/\"]."
			fi
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

TIME_PASSED=$[ $SECONDS-$START_TIME ]

echo "time=$TIME_PASSED" >> $GITHUB_OUTPUT

echo "[DEBUG] Contents of /tmp/:" > $DEBUG_OUT
ls -la /tmp/ > $DEBUG_OUT
echo "[DEBUG] Contents of /gobra/:" > $DEBUG_OUT
ls -la /gobra/ > $DEBUG_OUT
echo "[DEBUG] Contents of $STATS_TARGET:" > $DEBUG_OUT
ls -la $STATS_TARGET > $DEBUG_OUT

exit $EXIT_CODE
