#!/bin/sh

# Load variables from paths.sh if it exists
test -f "$(dirname $0)/paths.sh" && source "$(dirname $0)/paths.sh"

# Set this in your environment variable, for example:
#POEDITOR_BIN=/Users/me/Documents/Dev/POEditor/POEditor/bin/poeditor
if [ ! -x "$POEDITOR_BIN" ]; then
	echo You must define the POEDITOR_BIN variable to the path to the 'poeditor' Niji tool
	exit 1
fi

PROJ_DIR=$(dirname $0)/../ProjectName
LOCALIZABLE="$PROJ_DIR/Resources/Base.lproj/Localizable.strings"
#Context parsing
CONTEXT_JSON="$PROJ_DIR/Resources/Context.json"
MUSTACHE_TEMPLATE=$(dirname $0)/template.mustache
MUSTACHE_RESULT="$PROJ_DIR/Constants/JsonError.swift"

# Cf https://poeditor.com/account/api pour avoir le token et projet à utiliser
"$POEDITOR_BIN" --token "" --project "" --lang fr --ios "$LOCALIZABLE"  --context "$CONTEXT_JSON"
mustache "$CONTEXT_JSON" "$MUSTACHE_TEMPLATE" > "$MUSTACHE_RESULT"
