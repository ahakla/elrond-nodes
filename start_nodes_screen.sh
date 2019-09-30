#!/bin/bash

# This script will run all $NUMBER_OF_NODES nodes in Screen sessions.

# Exit script immediately on error:
set -e

# Source the general node config file, which should be in the same folder as the current script:
source ./nodes_config.sh

for i in $( seq 0 $((NUMBER_OF_NODES - 1)) ); do
	default_node_folder[i]="$NODE_FOLDER_PREFIX${USE_KEYS[i]}"  # default node folder for $USE_KEYS[i]
	cd ${default_node_folder[i]}

	suffix="$(printf "%02d" $((i+1)))"
	rest_api_port=$((8080+i))

	# Run node in virtual Screen session: $session_name.
	# The user can switch to this session with: screen -r $session_name
	# For a single node, this will be: screen -r node-01
	# To detach from that session again: <Ctrl+a>, followed by <d>
	session_name="$SESSION_PREFIX$suffix"
	screen -A -m -d -S $session_name ./node --rest-api-port $rest_api_port
done

echo
echo -e "${GREEN}Started${CYAN} $NUMBER_OF_NODES${NC} node instances with Screen."
echo
echo -e "Output 'screen -ls':"
echo ---------------
screen -ls
echo --------------
echo -e "Use ${CYAN}screen -r ${SESSION_PREFIX}##${NC} (## = 01, 02, etc.) to see the node dashboard."
echo -e "(Inside the Screen session, you can type: ${CYAN}'Ctrl+a', followed by 'd'${NC} to return to this shell.)"
