#!/bin/bash

# This script will run all $NUMBER_OF_NODES nodes in tmux sessions.

# Exit script immediately on error:
set -e

# Source the general node config file, which should be in the same folder as the current script:
source ./nodes_config.sh

for i in "${!USE_KEYS[@]}"; do
	default_node_folder[i]="$NODE_FOLDER_PREFIX${USE_KEYS[i]}"  # default node folder for $USE_KEYS[i]
	cd ${default_node_folder[i]}

	suffix="$(printf "%02d" $((i+1)))"
	rest_api_port=$((8080+i))

	# Run node in virtual tmux session: $session_name.
	# The user can switch to this session with: tmux a -t $session_name
	# For a single node, this will be: tmux a -t node-01
	# To detach from that session again: <Ctrl+b>, followed by <d>
	session_name="$SESSION_PREFIX$suffix"
	tmux new-session -d -s "$session_name"
	tmux send -t "$session_name" "./node --rest-api-port $rest_api_port" ENTER
done

echo
echo -e "${GREEN}Started${CYAN} $NUMBER_OF_NODES${NC} node instances with tmux."
echo
echo -e "Output 'tmux ls':"
echo ---------------
tmux ls
echo --------------
echo -e "Use ${CYAN}tmux a -t ${SESSION_PREFIX}##${NC} (## = 01, 02, etc.) to see the node dashboard."
echo -e "(Inside the tmux session, you can type: ${CYAN}'Ctrl+b', followed by 'd'${NC} to return to this shell.)"
