# Extracts the default value of every input declared in `action.yml` and prints
# one `name<TAB>default` pair per input. The default is empty for inputs that do
# not declare one. This keeps `action.yml` the single source of truth for the
# defaults, which `entrypoint.sh` compares the actual inputs against.

BEGIN { in_inputs = 0; n = 0; name = "" }

# the `inputs:` block starts here
/^inputs:[ \t]*$/ { in_inputs = 1; next }

# any other top-level key ends it
/^[A-Za-z]/ { in_inputs = 0; next }

# an input is declared by a key indented by two spaces
in_inputs && /^  [A-Za-z][A-Za-z0-9_]*:[ \t]*$/ {
	name = $1
	sub(/:$/, "", name)
	order[++n] = name
	def[name] = ""
	next
}

in_inputs && name != "" && /^    default:/ {
	line = $0
	sub(/^    default:[ \t]*/, "", line)
	sub(/[ \t]+#.*$/, "", line)          # strip a trailing comment
	gsub(/^["']|["']$/, "", line)        # strip surrounding quotes
	def[name] = line
	next
}

END { for (i = 1; i <= n; i++) print order[i] "\t" def[order[i]] }
