#!/bin/bash

# This script will run all $NUMBER_OF_NODES nodes in tmux sessions.

# Exit script immediately on error:
set -e

# Source the general node config file, which should be in the same folder as the current script:
source ./nodes_config.sh
scripts_folder=$PWD
use_rest_api=0	# initialize at zero

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

	# Start or restart the tmux session for each node
        if [ -z "$(tmux ls | grep $session_name)" ]; then
		tmux new-session -d -s "$session_name"
        else
                tmux send-keys -t "$session_name" C-c
		# Don't exit the script if lsof fails, this is an exception
		set +e && rest_api_port_node_process="$(sudo lsof -t -i:$rest_api_port -c node -a)" && set -e
                if [[ ! -z "$rest_api_port_node_process" ]]; then sudo kill "$rest_api_port_node_process"; fi
                tmux kill-session -t "$session_name" && tmux new-session -d -s "$session_name"
        fi

	# Only use the REST-API port explicitly
	if [ "${RESTAPI_KEYS[i]^^}" = "YES" ]; then
		use_rest_api=1
		tmux send -t "$session_name" "./node --rest-api-port $rest_api_port" ENTER
	else
		tmux send -t "$session_name" "./node" ENTER
	fi
done

echo
echo -e "${GREEN}Started${CYAN} $NUMBER_OF_NODES${NC} node instances with tmux."

# If use of REST-api is enabled,(re)start tmux session 'monitor' and invoke monitoring script
if [ "$use_rest_api" -eq "1" ]; then
	monitor_session_name="monitor"
        if [ -z "$(tmux ls | grep $monitor_session_name)" ]; then
                tmux new-session -d -s "$monitor_session_name"
        else
                tmux send-keys -t "$monitor_session_name" q
                tmux kill-session -t "$monitor_session_name" && tmux new-session -d -s "$monitor_session_name"
        fi

        tmux send -t "$monitor_session_name" "cd $scripts_folder" ENTER
        tmux send -t "$monitor_session_name" "bash check_autorestart_nodes_tmux.sh" ENTER
fi

echo
echo -e "Output 'tmux ls':"
echo ---------------
tmux ls
echo --------------
echo -e "Use ${CYAN}tmux a -t ${SESSION_PREFIX}##${NC} (## = 01, 02, etc.) to see the node dashboard."
if [ "$use_rest_api" -eq "1" ]; then echo -e "Use ${CYAN}tmux a -t $monitor_session_name${NC} to see the nodes monitor."; fi
echo -e "(Inside the tmux session, you can type: ${CYAN}'Ctrl+b', followed by 'd'${NC} to return to this shell.)"
