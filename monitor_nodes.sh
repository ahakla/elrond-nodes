#/bin/bash

# EXAMPLE:
# bash monitor_nodes.sh -w			--> shows all offline validator nodes
# bash monitor_nodes.sh string1 string2 string3	--> shows all nodes with string in their json info

# user needs to specify at least 1 search term as an argument (case sensitive)
if [ "$#" == 0 ]; then
	echo
	echo "Please specify at least 1 search term, like part of the node display name or initialNodesPk."
	echo "bash monitor_nodes.sh -w	--> Show all offline validator nodes"
	echo "Exiting script."
	echo
	exit
fi

# install jq if not yet installed
if ! [ -x "$(command -v jq)" ]; then
	sudo apt-get install -y jq
fi

#### get heartbeatstatus once to use later
heartbeatstatus=$(curl --silent http://localhost:8080/node/heartbeatstatus)

# creating the grep command, based on the arguments passed to the script
if [ "$#" == 1 ]; then
	if [ "$1" == "-w" ]; then
		echo
		echo "------------ OFFLINE VALIDATOR NODES ------------"
		(
			echo -e "initialNodesPk\tVal?\tUp(s)\tDown(s)\tNode name"
			grep -o '\{[^\{]*\"isActive\":false[^\}]*\"isValidator\":true[^\}]*\}' <<< ${heartbeatstatus} | \
				jq -s -c --raw-output 'sort_by(.nodeDisplayName)[] | [.hexPublicKey[0:12],.isValidator,.totalUpTimeSec,.totalDownTimeSec,.nodeDisplayName] | @csv'
		) | column -t -s,
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
echo "----------------- OFFLINE NODES -----------------"
(
	echo -e "initialNodesPk,Val?,Up(s),Down(s),Node name,version"
	eval "grep $grepstring"  <<< ${heartbeatstatus}  | grep '"isActive":false' | \
		jq -s -c --raw-output 'sort_by(.nodeDisplayName)[] | [.hexPublicKey[0:12],.isValidator,.totalUpTimeSec,.totalDownTimeSec,.nodeDisplayName,.versionNumber] | @csv'
) | column -t -s, | GREP_COLOR='49;91;4;5' egrep -i --color=always '.|$'
echo "-------------------------------------------------"
echo
echo "----------------- ONLINE  NODES -----------------"
(
	echo -e "initialNodesPk,Val?,Up(s),Down(s),Node name,version"
	eval "grep $grepstring"  <<< ${heartbeatstatus}  | grep '"isActive":true' | \
		jq -s -c --raw-output 'sort_by(.nodeDisplayName)[] | [.hexPublicKey[0:12],.isValidator,.totalUpTimeSec,.totalDownTimeSec,.nodeDisplayName,.versionNumber] | @csv'
) | column -t -s,
echo
