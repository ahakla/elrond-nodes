#/bin/bash

# user needs to specify at least 1 search term as an argument (case sensitive)
if [ "$#" == 0 ]; then
	echo "Please specify at least 1 search term, like part of the node display name or initialNodesPk. Exiting script."
	exit
fi

# install jq if not yet installed
if ! [ -x "$(command -v jq)" ]; then
	sudo apt-get install -y jq
fi

# creating the grep command, based on the arguments passed to the script
if [ "$#" == 1 ]; then
	grepstring="-o '\{[^\{]*'"$1"'[^\}]*\}'"
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
curl --silent http://localhost:8080/node/heartbeatstatus | eval "grep $grepstring" | grep '"isActive":true' | \
	jq -s -c --raw-output 'sort_by(.nodeDisplayName)[] | [.hexPublicKey[0:12],.isValidator,.totalUpTimeSec,.totalDownTimeSec,.nodeDisplayName] | @tsv'
echo
echo "----------------- OFFLINE NODES -----------------"
echo -e "initialNodesPk\tVal?\tUp(s)\tDown(s)\tNode name"
curl --silent http://localhost:8080/node/heartbeatstatus | eval "grep $grepstring" | grep '"isActive":false' | \
	jq -s -c --raw-output 'sort_by(.nodeDisplayName)[] | [.hexPublicKey[0:12],.isValidator,.totalUpTimeSec,.totalDownTimeSec,.nodeDisplayName] | @tsv'
echo "-------------------------------------------------"
echo
