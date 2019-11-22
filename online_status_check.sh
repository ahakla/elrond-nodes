#/bin/bash

# EXAMPLE:
# bash online_status_check.sh -w			--> shows all offline validator nodes
# bash online_status_check.sh string1 string2 string3	--> shows all nodes with string in their json info

# User needs to specify at least 1 search term as an argument (case sensitive)
if [ "$#" == 0 ]; then
	echo
	echo "Please specify at least 1 search term, like part of the node display name or initialNodesPk."
	echo "bash online_status_check.sh -w	--> Show all offline validator nodes"
	echo "Exiting script."
	echo
	exit
fi

# Search rest-api ports in 8080-8099 range with running node process, use first available port
use_port=0  # initialize at 0
for port in {8080..8099}; do
	lsof_string=$(sudo lsof -i -P -n | grep "$port (LISTEN)")
	if [ "${lsof_string:0:4}" == "node" ]; then
		use_port=$port
		echo "Using REST-API port $use_port..."
		break
	fi
done

if [ $use_port == 0 ]; then
	echo
	echo "No open REST-API ports with a node process have been found for ports 8080-8099."
	echo "Please use the --rest-api-port 8080 (or any port in 8080-8099) option for the node executable."
	echo "Exiting script."
	echo
	exit
fi

# install jq if not yet installed
if ! [ -x "$(command -v jq)" ]; then
	sudo apt-get install -y jq
fi

# get the heartbeatstatus
heartbeatstatus="$(curl --silent http://localhost:$use_port/node/heartbeatstatus)"

# creating the grep command, based on the arguments passed to the script
if [ "$#" == 1 ]; then
	if [ "$1" == "-w" ]; then
		echo
		echo "------------ OFFLINE VALIDATOR NODES ------------"
		echo -e "initialNodesPk\tVal?\tUp(s)\tDown(s)\tNode name"
		echo $heartbeatstatus | \
		grep -o '\{[^\{]*\"isActive\":false[^\}]*\"isValidator\":true[^\}]*\}' | \
			jq -s -c --raw-output 'sort_by(.nodeDisplayName)[] | [.hexPublicKey[0:12],.isValidator,.totalUpTimeSec,.totalDownTimeSec,.nodeDisplayName] | @tsv'
		echo "-------------------------------------------------"
		echo
		exit
	else
		grepstring="-o '\{[^\{]*'"$1"'[^\}]*\}'"
	fi
fi
if [ "$#" -ge 2 ]; then
	grepstring="-o -e '\{[^\{]*'"$1"'[^\}]*\}'"
	shift
	while test ${#} -gt 0; do
		grepstring="$grepstring -e '\{[^\{]*'"$1"'[^\}]*\}'"
		shift
	done
fi

# output the initialNodesPk, Validator?, Uptime (s), Downtime (s), and nodeDisplayName
echo
echo "----------------- ONLINE  NODES -----------------"
echo -e "initialNodesPk\tVal?\tUp(s)\tDown(s)\tNode name"
echo $heartbeatstatus | eval "grep $grepstring" | grep '"isActive":true' | \
	jq -s -c --raw-output 'sort_by(.nodeDisplayName)[] | [.hexPublicKey[0:12],.isValidator,.totalUpTimeSec,.totalDownTimeSec,.nodeDisplayName] | @tsv'
echo
echo "----------------- OFFLINE NODES -----------------"
echo -e "initialNodesPk\tVal?\tUp(s)\tDown(s)\tNode name"
echo $heartbeatstatus | eval "grep $grepstring" | grep '"isActive":false' | \
	jq -s -c --raw-output 'sort_by(.nodeDisplayName)[] | [.hexPublicKey[0:12],.isValidator,.totalUpTimeSec,.totalDownTimeSec,.nodeDisplayName] | @tsv'
echo "-------------------------------------------------"
echo
