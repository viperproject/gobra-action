#!/bin/sh

echo "Creating a docker image with Gobra image tag: $INPUT_IMAGEVERSION"
docker build -t docker-action --build-arg "image_version=$INPUT_IMAGEVERSION" --build-arg "image_name=$INPUT_IMAGENAME" /docker-action

# Directory where Gobra should write a stats.json file
export STATS_TARGET="/stats/"

# The verification time is reported by the inner container on stdout, since that
# container cannot write to $GITHUB_OUTPUT. Its output is captured here, where
# $GITHUB_OUTPUT does point at the runner's file commands, and the exit code of
# `docker run` is passed through a file because the pipe hides it from us.
RUN_LOG=$(mktemp)
RUN_STATUS=$(mktemp)

echo "Run Docker Action container"
{
docker run -e INPUT_CACHING -e INPUT_PROJECTLOCATION -e INPUT_INCLUDEPATHS -e INPUT_FILES -e INPUT_PACKAGES -e INPUT_EXCLUDEPACKAGES -e INPUT_CHOP \
  -e INPUT_OVERFLOW  -e INPUT_VIPERBACKEND -e INPUT_JAVAXSS -e INPUT_JAVAXMX -e INPUT_TIMEOUT -e INPUT_HEADERONLY -e INPUT_STATSFILE \
  -e INPUT_MODULE -e INPUT_RECURSIVE \
  -e INPUT_CONFIGFILE \
  -e INPUT_RESPECTFUNCTIONPREPERMAMOUNTS \
  -e INPUT_ASSUMEINJECTIVITYONINHALE -e INPUT_CHECKCONSISTENCY -e INPUT_MCEMODE \
  -e INPUT_REQUIRETRIGGERS \
  -e INPUT_ENABLEFRIENDCLAUSES \
  -e INPUT_UNSAFEWILDCARDOPTIMIZATION -e INPUT_MOREJOINS \
  -e INPUT_USEZ3API -e INPUT_DISABLENL \
  -e INPUT_PARALLELIZEBRANCHES -e INPUT_CONDITIONALIZEPERMISSIONS -e GITHUB_WORKSPACE -e GITHUB_REPOSITORY \
  -e STATS_TARGET -e DEBUG_MODE -v "$RUNNER_WORKSPACE:$GITHUB_WORKSPACE" -v "$INPUT_STATSFILE:$STATS_TARGET" \
  --workdir "$GITHUB_WORKSPACE" docker-action
echo $? > "$RUN_STATUS"
} | tee "$RUN_LOG"

EXIT_CODE=$(cat "$RUN_STATUS")
# the exit code is missing if the container was killed before it could be written
[ -n "$EXIT_CODE" ] || EXIT_CODE=1

# the line that `reportTime` of the inner entrypoint prints
TIME_PASSED=$(sed -n 's/^Gobra action: verification took \([0-9]*\)s$/\1/p' "$RUN_LOG" | tail -n 1)
if [ -n "$TIME_PASSED" ] && [ -n "$GITHUB_OUTPUT" ]; then
  echo "time=$TIME_PASSED" >> "$GITHUB_OUTPUT"
fi

rm -f "$RUN_LOG" "$RUN_STATUS"

exit "$EXIT_CODE"
