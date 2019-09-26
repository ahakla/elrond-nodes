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

	#run node in background session: tmux_session_name
	#user can switch to this session by using: tmux a -t $tmux_session_name
	#for a single node, this will be: tmux a -t testnet-01
	#to detach from that session again: <Ctrl+b>, followed by <d>
	tmux_session_name="$TMUX_SESSION_PREFIX$suffix"
	tmux new-session -d -s "$tmux_session_name"
	tmux send -t "$tmux_session_name" "cd ${default_node_folder[i]}" ENTER
	tmux send -t "$tmux_session_name" "./node --rest-api-port $rest_api_port" ENTER
done

echo
echo -e "${GREEN}Started${CYAN} $NUMBER_OF_NODES${NC} node instances with tmux."
echo
echo -e "Output 'tmux ls':"
echo ---------------
tmux ls
echo --------------
echo -e "Use ${CYAN}tmux a -t '${TMUX_SESSION_PREFIX}##'${NC} to see the node dashboard."
echo -e "(Inside the tmux session, you can type: ${CYAN}'Ctrl+b', followed by 'd'${NC} to return to this shell.)"
