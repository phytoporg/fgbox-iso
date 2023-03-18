#!/usr/bin/bash

################################################################################
# configure.sh - Configures an installed steam game
# 
# Usage: ./configure.sh
#     TODO
################################################################################

APP_ID=
PROTON=

while (( "$#" )); do
    if [[ "$1" == "--app-id" ]]; then
        shift
        APP_ID=$1
    elif [[ "$1" == "--proton" ]]; then
        PROTON=1
    fi

    shift
done

USERCONFIG_ID=$(ls /home/$USER/.steam/steam/userdata)
USERCONFIG_PATH="/home/$USER/.steam/steam/userdata/$USERCONFIG_ID"
#TODO: Sanity check USERCONFIG_PATH

LOCAL_VDF_PATH="$USERCONFIG_PATH/config/localconfig.vdf"
#TODO: Sanity check LOCAL_VDF_PATH

INSTALL_VDF_PATH="/home/$USER/.local/share/Steam/config/config.vdf"
#TODO: Sanity check INSTALL_VDF_PATH

if [ "$PROTON" ]; then
    TEMP_VDF_OUT=$(mktemp).vdf
    NOW=$(date +"%s")
    ./patch_vdf.py \
        --vdf-file "$LOCAL_VDF_PATH" \
        --data-path "UserLocalConfigStore.Software.Valve.Steam.apps.$APP_ID" \
        --data-value "{
            \"LaunchOptions\" : \"PROTON_USE_WINED3D=1 PROTON_NO_ESYNC=1 %command%\",
            \"ViewedLaunchEULA\" : \"1\",
            \"ViewedSteamPlay\" : \"1\",
            \"LastPlayed\" : \"$NOW\" }" \
            > "$TEMP_VDF_OUT"

    mv "$TEMP_VDF_OUT" "$LOCAL_VDF_PATH"

    ./patch_vdf.py \
        --vdf-file "$INSTALL_VDF_PATH" \
        --data-path "InstallConfigStore.Software.Valve.Steam.CompatToolMapping.$APP_ID" \
        --data-value "{
            \"name\" : \"proton_experimental\",
            \"config\" : \"\",
            \"priority\" : \"250\" }" \
            > "$TEMP_VDF_OUT"

    mv "$TEMP_VDF_OUT" "$INSTALL_VDF_PATH"

    # TODO: rm "$TEMP_VDF_OUT" (not yet, useful for debugging)
fi
