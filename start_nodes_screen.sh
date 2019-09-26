#!/bin/bash

# this script will run all $NUMBER_OF_NODES nodes

# exit script immediately on error
set -e

# source the general node config file, which should be in the same folder as the current script
source ./nodes_config.sh

for i in $( seq 0 $((NUMBER_OF_NODES - 1)) ); do
	default_node_folder[i]="$NODE_FOLDER_PREFIX${USE_KEYS[i]}"  # default node folder for $USE_KEYS[i]

	suffix="$(printf "%02d" $((i+1)))"
	rest_api_port=$((8080+i))

	#run node in virtual screen session: screen_session_name
	#user can recover this virtual screen with: screen -r $tmux_session_name
	#for a single node, this will be: screen -r testnet-01
	#to detach from that virtual screen again: <Ctrl+A>, followed by <d>
	screen_session_name="$SCREEN_SESSION_PREFIX$suffix"
	cd ${default_node_folder[i]}
  screen -A -m -d -S $screen_session_name ./node --rest-api-port $rest_api_port
done

echo
echo -e "${GREEN}Started${CYAN} $NUMBER_OF_NODES${NC} node instances with Screen."
echo
echo -e "Output 'screen -ls':"
echo ---------------
screen -ls
echo --------------
echo -e "Use ${CYAN}screen -r '${SCREEN_SESSION_PREFIX}##'${NC} to see the node dashboard."
echo -e "(Inside the screen session, you can type: ${CYAN}'Ctrl+A', followed by 'd'${NC} to return to this shell.)"
