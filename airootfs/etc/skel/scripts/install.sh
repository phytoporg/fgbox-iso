#!/usr/bin/bash

################################################################################
# install.sh - Installs a game using steamcmd
# 
# Usage: ./install.sh
#    --games-db <path to supported games database file>
#    --games-root <install root directory for steam games>
#    --steamuser <steam username for auth>
#    --steampassword <steam password for auth>
#    --game <game title or alias for installation>
################################################################################

GAMESDB_PATH=$HOME/data/gamesdb
GAMES_ROOT=$HOME/games
STEAMUSER=
STEAMPASSWORD=
GAME=

while (( "$#" )); do
    if [[ "$1" == "--games-db" ]]; then
        shift
        GAMESDB_PATH=$1
    elif [[ "$1" == "--games-root" ]]; then
        shift
        GAMES_ROOT=$1
    elif [[ "$1" == "--steamuser" ]]; then
        shift
        STEAMUSER=$1
    elif [[ "$1" == "--steampassword" ]]; then
        shift
        STEAMPASSWORD=$1
    elif [[ "$1" == "--game" ]]; then
        shift
        GAME=$1
    fi

    shift
done

if ! mkdir -p "$GAMES_ROOT" 2>/dev/null; then
    echo "Failed to create games root directory '$GAMES_ROOT'" >&2
    exit 1
fi

if [ ! -f "$GAMESDB_PATH" ]; then
    echo "Invalid or missing games database file: $GAMESDB_PATH" >&2
    exit 1
fi

if [ "$STEAMUSER" == "" ]; then
    echo "Steam username is required" >&2
    exit 1
fi

if [ "$STEAMPASSWORD" == "" ]; then
    echo "Steam password is required" >&2
    exit 1
fi

if [ "$GAME" = "" ]; then
    echo "Game is required" >&2
    exit 1
fi

if ! which steamcmd > /dev/null 2>&1; then
    echo "steamcmd not found! Please install it." >&2
    exit 1
fi

GAMEDB_SEARCH_RESULT=$(jq --arg game "${GAME}" '.games[] | select(.aliases[] | contains($game))' "$GAMESDB_PATH")
if [ "$GAMEDB_SEARCH_RESULT" == "" ]; then
    echo "Did not find any games matching search query '$GAME'." >&2
    exit 1
fi

# We need exactly one match.
GAMEDB_SEARCH_COUNT=$(echo "$GAMEDB_SEARCH_RESULT" | jq '.title' | wc -l)
if [ "$GAMEDB_SEARCH_COUNT" != "1" ]; then
    echo "Invalid search query '$GAME', found '$GAMEDB_SEARCH_COUNT' results" >&2
    exit 1
fi

GAMEDB_IS_SUPPORTED=$(echo "$GAMEDB_SEARCH_RESULT" | jq '.supported')
if [ "$GAMEDB_IS_SUPPORTED" == "false" ]; then
    echo "'$GAME' is not currently supported." >&2
    exit 1
fi

# Games database lines are formatted as:
# gametitle;alias1;alias2;etc|appid
GAMEDB_APPID=$(echo "$GAMEDB_SEARCH_RESULT" | jq '.appid')
GAMEDB_APPNAME=$(echo "$GAMEDB_SEARCH_RESULT" | jq '.title')
GAMEDB_PROTON=$(echo "$GAMEDB_SEARCH_RESULT" | jq '.proton')
INSTALL_PATH=$GAMES_ROOT/$GAME

echo "Installing '$GAMEDB_APPNAME' to '$INSTALL_PATH'..."

# Generate a script and run it via steamcmd
STEAMCMD_SCRIPT_PATH=$(mktemp)

echo "@ShutdownOnfailedCommand 1" > "$STEAMCMD_SCRIPT_PATH"
echo "@NoPromptForPassword 1" >> "$STEAMCMD_SCRIPT_PATH"

if [ "$GAMEDB_PROTON" == "true" ]; then
    echo "@sSteamCmdForcePlatformType windows" >> "$STEAMCMD_SCRIPT_PATH"
fi

echo "force_install_dir $INSTALL_PATH" >> "$STEAMCMD_SCRIPT_PATH"
echo "login $STEAMUSER $STEAMPASSWORD" >> "$STEAMCMD_SCRIPT_PATH"
echo "app_update $GAMEDB_APPID validate" >> "$STEAMCMD_SCRIPT_PATH"
echo "quit" >> "$STEAMCMD_SCRIPT_PATH"

steamcmd +runscript "$STEAMCMD_SCRIPT_PATH"
rm "$STEAMCMD_SCRIPT_PATH"

if [ "$GAMEDB_PROTON" == "true" ]; then
    ./configure.sh --app-id "$GAMEDB_APPID" --proton
else
    ./configure.sh --app-id "$GAMEDB_APPID" 
fi
