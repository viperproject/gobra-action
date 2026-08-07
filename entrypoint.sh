#!/bin/sh

echo "Creating a docker image with Gobra image tag: $INPUT_IMAGEVERSION"
docker build -t docker-action --build-arg "image_version=$INPUT_IMAGEVERSION" --build-arg "image_name=$INPUT_IMAGENAME" /docker-action

# Directory where Gobra should write a stats.json file
export STATS_TARGET="/stats/"

# Inputs that keep having an effect in config file mode. Every other input maps to an
# option of Gobra, which is read from the JSON config instead. `files`, `packages` and
# `recursive` are listed here because they are rejected with a dedicated error message.
CONFIG_MODE_EFFECTIVE_INPUTS="configFile printConfig caching statsFile javaXss javaXmx timeout imageName imageVersion files packages recursive"

# Collects the inputs that were set to a non-default value but have no effect in config
# file mode. `action.yml` is the single source of truth for the defaults.
export IGNORED_INPUTS=""
if [ -n "$INPUT_CONFIGFILE" ]; then
	IFS_BACKUP="$IFS"
	while IFS="$(printf '\t')" read -r NAME DEFAULT; do
		[ -n "$NAME" ] || continue
		case " $CONFIG_MODE_EFFECTIVE_INPUTS " in *" $NAME "*) continue ;; esac
		# an unset variable means that the input was not provided, so it is not reported
		if VALUE=$(printenv "INPUT_$(echo "$NAME" | tr '[:lower:]' '[:upper:]')") \
			&& [ "$VALUE" != "$DEFAULT" ]; then
			IGNORED_INPUTS="$IGNORED_INPUTS $NAME"
		fi
	done <<-EOF
	$(awk -f /defaults.awk /action.yml)
	EOF
	IFS="$IFS_BACKUP"
fi

echo "Run Docker Action container"
docker run -e INPUT_CACHING -e INPUT_PROJECTLOCATION -e INPUT_INCLUDEPATHS -e INPUT_FILES -e INPUT_PACKAGES -e INPUT_EXCLUDEPACKAGES -e INPUT_CHOP \
  -e INPUT_OVERFLOW  -e INPUT_VIPERBACKEND -e INPUT_JAVAXSS -e INPUT_JAVAXMX -e INPUT_TIMEOUT -e INPUT_HEADERONLY -e INPUT_STATSFILE \
  -e INPUT_MODULE -e INPUT_RECURSIVE \
  -e INPUT_CONFIGFILE -e INPUT_PRINTCONFIG \
  -e INPUT_RESPECTFUNCTIONPREPERMAMOUNTS \
  -e INPUT_ASSUMEINJECTIVITYONINHALE -e INPUT_CHECKCONSISTENCY -e INPUT_MCEMODE \
  -e INPUT_REQUIRETRIGGERS \
  -e INPUT_ENABLEFRIENDCLAUSES \
  -e INPUT_UNSAFEWILDCARDOPTIMIZATION -e INPUT_MOREJOINS \
  -e INPUT_USEZ3API -e INPUT_DISABLENL \
  -e INPUT_PARALLELIZEBRANCHES -e INPUT_CONDITIONALIZEPERMISSIONS -e GITHUB_WORKSPACE -e GITHUB_REPOSITORY \
  -e IGNORED_INPUTS \
  -e STATS_TARGET -e DEBUG_MODE -v "$RUNNER_WORKSPACE:$GITHUB_WORKSPACE" -v "$INPUT_STATSFILE:$STATS_TARGET" \
  --workdir "$GITHUB_WORKSPACE" docker-action
