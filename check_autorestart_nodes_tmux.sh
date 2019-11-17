#!/bin/bash

# This script is used to check nodes' statuses and to autorestart if necessary
#

# Exit script immediately on error:
set -e

# Source the general node config file, which should be in the same folder as the current script:
source ./nodes_config.sh

# Define criteria to restart of even reinstall node(s)
SLEEP_SECS=20					# check every ... seconds
MIN_ERD_NUM_CONNECTED_PEERS_T1_SECS=60		# check erd_num_connected_peers after T1 seconds
MIN_ERD_NUM_CONNECTED_PEERS_AFTER_T1=5		# minimum erd_num_connected_peers after T1 seconds

# The lines below are for later....
#MIN_ERD_NUM_CONNECTED_PEERS_T2_SECS=120		# check erd_num_connected_peers after T2 seconds
#MIN_ERD_NUM_CONNECTED_PEERS_AFTER_T2=10		# minimum erd_num_connected_peers after T2 seconds
#MIN_ERD_NUM_CONNECTED_PEERS_MAX_TRIES=3		# reinstall node after ... restart attempts

# Info message
printf "\n${CYAN}This monitoring script will check the nodes' statuses every $SLEEP_SECS seconds.${NC}"
printf "\n${CYAN}Press q to stop this script, press i for node uptime info.${NC}\n"

# Enable exiting script with a single keystroke
if [ -t 0 ]; then
  SAVED_STTY="`stty --save`"
  stty -echo -icanon -icrnl time 0 min 0
fi

# Define functions
exit_script () {
	# Reset keyboard input configuration to initial settings
	if [ -t 0 ]; then stty "$SAVED_STTY"; fi
	exit
}

initialize_clock () {
	local node_index="$1"
        begin[node_index]=$(date +%s)
        diff[node_index]=0
}

check_node_process () {
	local node_index="$1"
        local rest_api_port=$((8080+node_index))
	# Don't exit the script if lsof fails, this is an exception
	set +e && local rest_api_port_node_process="$(sudo lsof -t -i:$rest_api_port -c node -a)" && set -e

	if [[ -z "$rest_api_port_node_process" ]]; then
		local message="cannot find node process on rest-api port $rest_api_port"
		restart $node_index "$message"
	fi
}

check_erd_num_connected_peers () {
	local node_index="$1"
	local test_value="$2"
	if [[ ${diff[node_index]} -ge $MIN_ERD_NUM_CONNECTED_PEERS_T1_SECS && $test_value -lt $MIN_ERD_NUM_CONNECTED_PEERS_AFTER_T1 ]]; then
		local message="after at least $MIN_ERD_NUM_CONNECTED_PEERS_T1_SECS seconds, erd_num_connected_peers < $MIN_ERD_NUM_CONNECTED_PEERS_AFTER_T1"
		restart $node_index "$message"
	fi
}

restart () {
	local node_index="$1"
	local message="$2"
	printf "${RED}Restarting node $((node_index+1))/$list_node_length: $message${NC}\n"

        default_node_folder[node_index]="$NODE_FOLDER_PREFIX${USE_KEYS[node_index]}"  # default node folder for $USE_KEYS[i]
	if [[ ! -d ${default_node_folder[node_index]} ]]; then
		printf "${RED}Cannot find default node folder: ${default_node_folder[node_index]}! Exiting script.${NC}\n"
		exit_script
	fi

        suffix="$(printf "%02d" $((node_index+1)))"
        rest_api_port=$((8080+node_index))
        session_name="$SESSION_PREFIX$suffix"

        if [ -z "$(tmux ls | grep $session_name)" ]; then
		printf "${RED}Cannot find tmux session $session_name! Exiting script.${NC}\n"
		exit_script
        else
                tmux send-keys -t "$session_name" C-c
		# Don't exit the script if lsof fails, this is an exception
		set +e && local rest_api_port_node_process="$(sudo lsof -t -i:$rest_api_port -c node -a)" && set -e
		if [[ ! -z "$rest_api_port_node_process" ]]; then sudo kill "$rest_api_port_node_process"; fi
		tmux kill-session -t "$session_name" && tmux new-session -d -s "$session_name"
        fi

        # Use rest-api-port by default
	tmux send -t "$session_name" "cd ${default_node_folder[node_index]}" ENTER
        tmux send -t "$session_name" "./node --rest-api-port $rest_api_port" ENTER

	# Initialize clock for the restarted node
	initialize_clock $node_index
}

show_info () {
	echo
	for i in $list_node_index; do
		secs[i]=$((${diff[i]} % 60))
		mins[i]=$((${diff[i]} / 60 % 60))
		hours[i]=$((${diff[i]} / 60 / 60 % 24))
		days[i]=$((${diff[i]} / 60 / 60 / 24))
		printf "${CYAN}Node %d/%d has run for %d days, %02d:%02d:%02d\n${NC}" $((i+1)) $list_node_length ${days[i]} ${hours[i]} ${mins[i]} ${secs[i]}
	done
}

# Initialization
list_node_index="${!USE_KEYS[@]}"
list_node_length="${#USE_KEYS[@]}"
for i in $list_node_index; do
	initialize_clock $i
done
keypress=''

# Start monitoring
while [[ "x$keypress" != "xq" && "x$keypress" != "xQ" ]]; do
	for i in $list_node_index; do

	        # Check if rest-api-port is open
	        if [[ "${RESTAPI_KEYS[i]^^}" == "YES" ]]; then

		        rest_api_port=$((8080+i))
			# Don't exit the script if curl fails, this is an exception
			set +e && node_status[i]="$(curl --silent http://localhost:$rest_api_port/node/status)" && set -e

			if [[ ! -z $(echo ${node_status[i]} | jq '.details.erd_app_version') ]]; then

				# Only printf header once
				if [ "$i" -eq "0" ]; then
					printf "\n${GREEN} Node ${NC}|${GREEN} Sync ${NC}|${GREEN} initNodes Pk ${NC}|"
					printf "${GREEN} Typ ${NC}|${GREEN} Node Display Name ${NC}|${GREEN} Shard ${NC}|"
					printf "${GREEN} ConP ${NC}|${GREEN} Synch Block Nonce ${NC}|${GREEN} Consensus Round${NC}\n"
				fi

				erd_is_syncing_str[i]="OK"
				erd_is_syncing[i]="$(echo ${node_status[i]} | jq '.details.erd_is_syncing')"
				if [[ $((erd_is_syncing[i])) != 0 ]]; then erd_is_syncing_str[i]="!!"; fi
				erd_node_display_name[i]="$(echo ${node_status[i]} | jq '.details.erd_node_display_name' | tr -d '"')"
				erd_public_key_block_sign[i]="$(echo ${node_status[i]} | jq '.details.erd_public_key_block_sign' | tr -d '"')"
				erd_shard_id[i]="$(echo ${node_status[i]} | jq '.details.erd_shard_id')"
				if [[ $((erd_shard_id[i]-1000000)) -gt 0 ]]; then erd_shard_id[i]="meta"; fi
				erd_node_type[i]="$(echo ${node_status[i]} | jq '.details.erd_node_type' | tr -d '"')"
				erd_num_connected_peers[i]="$(echo ${node_status[i]} | jq '.details.erd_num_connected_peers')"
				erd_nonce[i]="$(echo ${node_status[i]} | jq '.details.erd_nonce')"
				erd_probable_highest_nonce[i]="$(echo ${node_status[i]} | jq '.details.erd_probable_highest_nonce')"
				erd_synchronized_round[i]="$(echo ${node_status[i]} | jq '.details.erd_synchronized_round')"
				erd_current_round[i]="$(echo ${node_status[i]} | jq '.details.erd_current_round')"
				printf "%2d/%-2d |  %2s  | %-12s | %-3s | %-17s | %5s | %4d | %8d/%-8d | %8d/%-8d\n" \
					$((i+1)) $list_node_length "${erd_is_syncing_str[i]}" "${erd_public_key_block_sign[i]:0:12}" "${erd_node_type[i]:0:3}" "${erd_node_display_name[i]:0:17}" "${erd_shard_id[i]}" \
					"${erd_num_connected_peers[i]}" "${erd_nonce[i]}" "${erd_probable_highest_nonce[i]}" \
					"${erd_synchronized_round[i]}" "${erd_current_round[i]}"

				check_erd_num_connected_peers $i "${erd_num_connected_peers[i]}"
			fi
		else
			printf "${RED}The REST-api port for node %d/%d has not been opened. Cannot monitor node.${NC}\n" $((i+1)) $list_node_length
		fi
	done

	for count in $(seq 1 $SLEEP_SECS); do
		keypress="`cat -v`"
		sleep 1

		now=$(date +%s)
		for i in $list_node_index; do diff[i]=$(($now - ${begin[i]})); done
		if [[ "x$keypress" == "xq" || "x$keypress" == "xQ" ]]; then
			break
		fi
		if [[ "x$keypress" == "xi" || "x$keypress" == "xI" ]]; then
			show_info
		fi
	done

	# Check node process only after the first sleep
	check_node_process $i
done

# Message upon exit
show_info
exit_script
