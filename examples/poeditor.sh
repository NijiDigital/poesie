#!/bin/sh

# Load variables from paths.sh if it exists
test -f "$(dirname $0)/paths.sh" && source "$(dirname $0)/paths.sh"

# Set this in your environment variable, for example:
#POEDITOR_BIN=/Users/me/Documents/Dev/POEditor/POEditor/bin/poeditor
if [ ! -x "$POEDITOR_BIN" ]; then
	echo You must define the POEDITOR_BIN variable to the path to the 'poeditor' Niji tool
	exit 1
fi


### Project-specific variables ###
PROJ_DIR=$(dirname $0)/../ProjectName
LOCALIZABLE="$PROJ_DIR/Resources/Base.lproj/Localizable.strings"
# Fill the following with values from https://poeditor.com/account/api
API_TOKEN=""
PROJECT_ID=""


### Run the Script ###
"$POEDITOR_BIN" --token "$API_TOKEN" --project "$PROJECT_ID" --lang fr --ios "$LOCALIZABLE"
