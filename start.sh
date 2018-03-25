#!/bin/bash

GSLT=${gslt}

if [ -z "$GSLT" ]; then
    echo "You must set GSLT env var"
    exit -1
fi

set -ex

# update game
steamcmd +login anonymous +force_install_dir ~/csgo-ds +app_update 740 +quit

# start game
cd csgo-ds

# casual
./srcds_run -game csgo -console -usercon +game_type 0 +game_mode 1 +mapgroup mg_active +map de_dust2 +sv_setsteamaccount $GSLT -net_port_try 1
