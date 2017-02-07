#!/bin/sh

# Load variables from paths.sh if it exists
test -f "$(dirname $0)/paths.sh" && source "$(dirname $0)/paths.sh"

# Set this in your environment variable, for example:
#POESIE_BIN=/Users/me/Documents/Dev/Poesie/bin/poesie
if [ ! -x "$POESIE_BIN" ]; then
  echo You must define the POESIE_BIN variable to the path to the 'poesie' tool
  exit 1
fi


### Project-specific variables ###
PROJ_DIR=$(dirname $0)/../ProjectName
LOCALIZABLE="$PROJ_DIR/Resources/Base.lproj/Localizable.strings"
# Fill the following with values from https://poeditor.com/account/api
API_TOKEN=""
PROJECT_ID=""


### Run the Script ###
"$POESIE_BIN" --token "$API_TOKEN" --project "$PROJECT_ID" --lang fr --ios "$LOCALIZABLE"
