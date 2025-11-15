log() {
  echo "$*" > /dev/stderr
}

err() {
  log "error: $*"
  exit 1
}

json() {
  # Usage: stdin is json content, $1 is python-formatted query
  # Example: `xcodebuild -list -json | json '["project"]["configurations"][0]'`
  # Using this instead of `jq` because we can't depend on all devs having $(jq)
  # installed, but python is already a build dependency for QS
  local query=$1
  python3 -c '
import json
import sys

stdin = sys.stdin.read()
content = json.loads(stdin)

json_keys = sys.argv[1]
output = eval(f"{content}{json_keys}")

# Strips quotes if there is a simple result
if isinstance(output, str):
  print(output)
# Pretty-print arrays and dicts
else:
  print(json.dumps(output, indent=4))
' "${query}"
}
