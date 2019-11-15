#!/bin/bash

# This script is used to check nodes' statuses and to autorestart if necessary
#

# Exit script immediately on error:
set -e

# Source the general node config file, which should be in the same folder as the current script:
source ./nodes_config.sh

if [ -t 0 ]; then
  SAVED_STTY="`stty --save`"
  stty -echo -icanon -icrnl time 0 min 0
fi

SLEEP_SECS=20		# check every 20 seconds

list_node_index="${!USE_KEYS[@]}"
list_node_length="${#USE_KEYS[@]}"
begin=$(date +%s)
keypress=''
while [ "x$keypress" = "x" ]; do
	echo
	for i in $list_node_index; do
	        rest_api_port=$((8080+i))
		node_status[i]="$(curl --silent http://localhost:$rest_api_port/node/status)"

	        # Check if rest-api-port is open
	        if [[ "${RESTAPI_KEYS[i]^^}" == "YES" ]]; then
			if [[ ! -z $(echo ${node_status[i]} | jq '.details.erd_app_version') ]]; then
				erd_node_display_name[i]="$(echo ${node_status[i]} | jq '.details.erd_node_display_name')"
				erd_shard_id[i]="$(echo ${node_status[i]} | jq '.details.erd_shard_id')"
				if [[ $((erd_shard_id[i]-1000000)) -gt 0 ]]; then erd_shard_id[i]="meta"; fi
				erd_num_connected_peers[i]="$(echo ${node_status[i]} | jq '.details.erd_num_connected_peers')"
				printf "Node %d/%d | %-20s | Shard %-4s | %d connected peers\n" \
					$((i+1)) $list_node_length "${erd_node_display_name[i]}" "${erd_shard_id[i]}" \
					"${erd_num_connected_peers[i]}"
			else
				printf "Node %d/%d down!\n" \
					$((i+1)) $list_node_length
			fi
		else
			echo "The REST-api port for node $i has not been opened. Will not check node status."
			echo "Set RESTAPI_KEYS to yes to enable check and autorestart for your node."
			exit
		fi
	done

	for count in $(seq 1 $SLEEP_SECS); do
		keypress="`cat -v`"
		sleep 1

		now=$(date +%s)
		diff=$(($now - $begin))
		mins=$(($diff / 60))
		secs=$(($diff % 60))
		hours=$(($diff / 3600))
		days=$(($diff / 86400))
		if [ "x$keypress" != "x" ]; then
			break
		fi
	done
done

if [ -t 0 ]; then stty "$SAVED_STTY"; fi

printf "\nYou pressed %s after %d Days, %02d:%02d:%02d\n" $keypress $days $hours $mins $secs
exit 0
