#!/bin/bash

# This script will first install for $NUMBER_OF_NODES nodes, then quickly stop the nodes
# in tmux, and restart with only a second of offline time.

# Exit script immediately on error:
set -e

# Source the general node config file, which should be in the same folder as the current script:
scripts_folder=$(dirname "$(realpath $0)")
source $scripts_folder/nodes_config.sh

# Create $ELROND_FOLDER and $BACKUP_ALLKEYS_FOLDER if they do not exist:
mkdir -p $ELROND_FOLDER $BACKUP_ALLKEYS_FOLDER

# Recursively search $ELROND_FOLDER and $BACKUP_ALL_KEYS_FOLDER for folders that contain both pem key files
# and put them in a string of strings called $folders_with_keys:
folders_with_keys=$(find $ELROND_FOLDER $BACKUP_ALLKEYS_FOLDER -type d \
		-exec test -f '{}'/initialNodesSk.pem -a -f '{}'/initialBalancesSk.pem \; -print)

# Check if all keys that were specified in $USE_KEYS are available:
for i in "${!USE_KEYS[@]}"; do
	# keys_found[i] is "yes" as soon as the pem key files for $USE_KEYS[i] are found.
	keys_found[i]="no"			# initialize at "no"

	echo
	echo -e "Searching pem key files for initialNodesPk ${CYAN}${USE_KEYS[i]}...${NC}"
	for folder in $folders_with_keys; do

		# Search for matching initialNodesPk's in each folder that contains both pem key files:
		contents_initialNodesSk=$(<"$folder/initialNodesSk.pem")
		if [[ "${USE_KEYS[i]}" == "${contents_initialNodesSk:27:12}" ]]; then
			# If the pem key files for $USE_KEYS[i] are found in $folder, then...
			keys_found[i]="yes"
		fi
	done

	if [[ ${keys_found[i]} == "no" ]]; then
		# If the pem key files for $USE_KEYS[i] can't be found anywhere:

		echo -e "${RED}Could not find${NC} pem key files for initialNodesPk ${USE_KEYS[i]}... anywhere!"
		echo -e "${RED}Please re-customize nodes_config.sh!${NC} Exiting script."
		exit
	fi
done

# Check if the user has no nodes running outside of tmux:
outside_tmux_answer=""			# initialize as empty
while [[  $outside_tmux_answer != "n" && $outside_tmux_answer != "exit" ]] ; do
	read -p "Do you have any nodes running OUTSIDE of tmux on this system? [n/exit] : " outside_tmux_answer

	if [[ $outside_tmux_answer == "exit" ]] ; then
		echo -e -n "${RED}Please only use this script to update nodes that are running "
		echo -e "inside tmux or have been stopped!${NC} Exiting script."
		exit

	elif [[ $outside_tmux_answer != "n" ]] ; then
		echo -e "${RED}Please answer \"n\" or \"exit\".${NC} Repeating the question."
	fi
done

# Check if the user has customized nodes_config.sh:
cust_answer=""			# initialize as empty
while [[  $cust_answer != "y" && $cust_answer != "exit" ]] ; do
	read -p "Have you customized nodes_config.sh? [y/exit] : " cust_answer

	if [[ $cust_answer == "exit" ]] ; then
		echo -e "${RED}Please customize nodes_config.sh first!${NC} Exiting script."
		exit

	elif [[ $cust_answer != "y" ]] ; then
		echo -e "${RED}Please answer \"y\" or \"exit\".${NC} Repeating the question."
	fi
done

for i in "${!USE_KEYS[@]}"; do
	default_node_folder[i]="$NODE_FOLDER_PREFIX${USE_KEYS[i]}"  # default node folder for $USE_KEYS[i]

	if [[ "${KEEPDB_KEYS[i]^^}" == "NO" && -d ${default_node_folder[i]}/db ]]; then

		# Ask for confirmation before removing /db folder:
		echo -n "Are you sure you want to remove the /db folder for initialNodesPk "
		read -p "${USE_KEYS[i]}...? [y/n] : " are_you_sure[i]
		if [[ ${are_you_sure[i]} == "y" ]]; then
			echo "Will remove the /db folder for initialNodesPk ${USE_KEYS[i]}..."
		else
			echo -n "Despite the settings in nodes_config.sh, will keep the /db "
			echo "folder for initialNodesPk ${USE_KEYS[i]}..."
		fi
	fi
done

# To be safe, back up all the keys that have been found in $folders_with_keys to $BACKUP_ALLKEYS_FOLDER:
for folder in $folders_with_keys; do
	contents_initialNodesSk=$(<"$folder/initialNodesSk.pem")
	key_id="${contents_initialNodesSk:27:12}"

	# if the pem key files for $key_id are found in $folder
	# then create a backup of the pem key files in $BACKUP_ALLKEYS_FOLDER/$key_id
	# if a backup does not yet exist, avoiding a cp `are the same file` error
	mkdir -p "$BACKUP_ALLKEYS_FOLDER/$key_id"
	if [[ $folder != "$BACKUP_ALLKEYS_FOLDER/$key_id" ]]; then
		cp -n $folder/initial{Nodes,Balances}Sk.pem "$BACKUP_ALLKEYS_FOLDER/$key_id"
	fi
done

if [[ "${CLEANUP^^}" == "YES" ]]; then
	# Clean up:
	# Remove all $folders_with_keys, except for $default_backup_keys_folder[i], $default_node_folder[i]/config,
	# or any of the elrond-config / elrond-go repo subfolders.
	# If the folder's basename is config, then recursively remove the parent folder too, assuming a node folder structure.

	for folder in $folders_with_keys; do

		match=0
		for i in "${!USE_KEYS[@]}"; do
		 	if [[ "$folder" == "${default_backup_keys_folder[i]}" || "$folder" == "${default_node_folder[i]}/config" || \
				"$folder" == "$ELROND_FOLDER/elrond-config/"* || "$folder" == "$ELROND_FOLDER/elrond-go/"* ]]; then
				# If the pem keys in $folder reside in $default_backup_keys_folder[i], $default_node_folder[i]/config,
				# or any of the elrond-config / elrond-go repo subfolders... then do not remove $folder for $USE_KEY[i].
			        match=1
			        break
			fi
		done

		if [[ $match == 0 ]]; then
			if [[ "$(basename $folder)" == "config" ]]; then
				rm_folder="$(dirname $folder)"
			else
				rm_folder="$folder"
			fi

			if [[ -d $rm_folder && "$(dirname $rm_folder)" != $BACKUP_ALLKEYS_FOLDER ]]; then
				read -p "Are you sure you want to recursively remove the folder $rm_folder? [y/n] : " are_you_sure_rm_folder
				if [[ $are_you_sure_rm_folder == "y" ]]; then
					echo "Recursively removing $rm_folder."
					sudo rm -rf $rm_folder
				else
					echo "Despite the settings in nodes_config.sh, keeping the folder $rm_folder."
				fi
			fi
		fi
	done

fi

##################################################################################
##                        START UPDATES AND INSTALLATION                        ##
##################################################################################

echo -e
echo -e "${GREEN}--> installing elrond-go nodes as specified in nodes_config.sh...${NC}"
echo -e

# Making sure the distro is up-to-date:
sudo apt update && sudo apt dist-upgrade -y

# Install some dependencies:
sudo apt install -y git curl tmux jq build-essential

# Check if go is already installed:
if ! [ -x "$(command -v go)" ];

    then
      # get the latest version of GO for amd64 & installing it
      echo -e "${RED}GO is not installed on your system${NC}"
      GO_LATEST=$(curl -sS https://golang.org/VERSION?m=text)
      echo -e
      echo -e "${GREEN}The latest version Go is:${CYAN}$GO_LATEST${NC}"
      echo -e "${GREEN}Installing it now...${NC}"
      echo -e
      wget https://dl.google.com/go/$GO_LATEST.linux-amd64.tar.gz
      sudo tar -C /usr/local -xzf $GO_LATEST.linux-amd64.tar.gz
      rm $GO_LATEST.linux-amd64.tar.gz

    else
      VER=$(go version)
      echo -e
      echo -e "${GREEN}GO is already installed: ${CYAN}$VER${NC}${GREEN}...skipping install${NC}"

  fi

# Clean up old installations:
if [[ -d $ELROND_FOLDER/elrond-go ]]; then
	sudo rm -rf $ELROND_FOLDER/elrond-go
fi
if [[ -d $ELROND_FOLDER/elrond-config ]]; then
	sudo rm -rf $ELROND_FOLDER/elrond-config
fi

cd $ELROND_FOLDER

# Clone the elrond-go & elrond-config repos:
git clone https://github.com/ElrondNetwork/elrond-go
cd $ELROND_FOLDER/elrond-go && git checkout --force $ELRONDGO_VER
cd $ELROND_FOLDER
git clone https://github.com/ElrondNetwork/elrond-config
cd $ELROND_FOLDER/elrond-config && git checkout --force $ELRONDCONFIG_VER

# Compile elrond-go:
cd $ELROND_FOLDER/elrond-go
GO111MODULE=on go mod vendor
cd $ELROND_FOLDER/elrond-go/cmd/node && go build -i -v -ldflags="-X main.appVersion=$(git describe --tags --long --dirty)"

# Build key generator:
cd $ELROND_FOLDER/elrond-go/cmd/keygenerator
go build

# Prepare for appending settings for the new nodes identities:
use_keys_string_new="${USE_KEYS[@]}"
restapi_keys_string_new="${RESTAPI_KEYS[@]}"
keepdb_keys_string_new="${KEEPDB_KEYS[@]}"
keeplogs_keys_string_new="${KEEPLOGS_KEYS[@]}"
keepstats_keys_string_new="${KEEPSTATS_KEYS[@]}"

# Create new pem key files for the remaining nodes and make a backup:
number_of_existing_nodes=${#USE_KEYS[@]}
number_of_new_nodes=$((NUMBER_OF_NODES-number_of_existing_nodes))
for new_node in $( seq 0 $((number_of_new_nodes - 1)) ); do
	cd $ELROND_FOLDER/elrond-go/cmd/keygenerator	# just to be sure
	./keygenerator

	contents_initialNodesSk=$(<"initialNodesSk.pem")
	key_id="${contents_initialNodesSk:27:12}"

	# Create a backup of the pem key files in $BACKUP_ALLKEYS_FOLDER/$key_id:
	mkdir -p "$BACKUP_ALLKEYS_FOLDER/$key_id"
	cp initial{Nodes,Balances}Sk.pem "$BACKUP_ALLKEYS_FOLDER/$key_id"

	default_new_node_folder="$NODE_FOLDER_PREFIX$key_id"  # default node folder for $key_id
	mkdir -p $default_new_node_folder/config
	cp initial{Nodes,Balances}Sk.pem $default_new_node_folder/config

	# Appending new node identities to settings:
	use_keys_string_new=$(echo "$use_keys_string_new $key_id" | sed -e 's/^[ \t]*//')
        restapi_keys_string_new=$(echo "$restapi_keys_string_new yes" | sed -e 's/^[ \t]*//')           # default is yes
	keepdb_keys_string_new=$(echo "$keepdb_keys_string_new yes" | sed -e 's/^[ \t]*//')		# safest default is yes
	keeplogs_keys_string_new=$(echo "$keeplogs_keys_string_new no" | sed -e 's/^[ \t]*//')		# default is no
	keepstats_keys_string_new=$(echo "$keepstats_keys_string_new no" | sed -e 's/^[ \t]*//')	# default is no

	# Copy fresh elrond-config to the node config folder and insert friendly node names in prefs.toml
	cp $ELROND_FOLDER/elrond-config/*.* $default_new_node_folder/config
	i=$((number_of_existing_nodes + new_node))
	if [ ! "${NODE_NAMES[i]}" == "" ]; then
	    sed -i 's|NodeDisplayName = ""|NodeDisplayName = "'"${NODE_NAMES[i]}"'"|g' \
		$default_new_node_folder/config/prefs.toml
	fi

	# Copy fresh node binary to $default_new_node_folder:
	cp $ELROND_FOLDER/elrond-go/cmd/node/node $default_new_node_folder
done

# Modify ./nodes_config.sh to include new node identities:
sed -i 's/^USE_KEYS=([^)]*)/USE_KEYS=('"$use_keys_string_new"')/g' $scripts_folder/nodes_config.sh
sed -i 's/^RESTAPI_KEYS=([^)]*)/RESTAPI_KEYS=('"$restapi_keys_string_new"')/g' $scripts_folder/nodes_config.sh
sed -i 's/^KEEPDB_KEYS=([^)]*)/KEEPDB_KEYS=('"$keepdb_keys_string_new"')/g' $scripts_folder/nodes_config.sh
sed -i 's/^KEEPLOGS_KEYS=([^)]*)/KEEPLOGS_KEYS=('"$keeplogs_keys_string_new"')/g' $scripts_folder/nodes_config.sh
sed -i 's/^KEEPSTATS_KEYS=([^)]*)/KEEPSTATS_KEYS=('"$keepstats_keys_string_new"')/g' $scripts_folder/nodes_config.sh

# Stop running nodes and copy fresh installs to node folders
echo
for i in "${!USE_KEYS[@]}"; do

	# Kill an existing tmux session for this node, if it exists
        suffix="$(printf "%02d" $((i+1)))"
        session_name="$SESSION_PREFIX$suffix"
        if [ ! -z "$(tmux ls | grep $session_name)" ]; then
                tmux send-keys -t "$session_name" C-c
		echo -e "${CYAN}Killing existing tmux session $session_name...${NC}"
                tmux kill-session -t "$session_name"
        fi

	# $mainfolder_existing_node[i] is folder where pem key files for $USE_KEYS[i] are found...
	# ...and for which all the required ../db ../logs ../stats folders exist.
	mainfolder_existing_node[i]=""	# initialize at ""

	echo
	echo -e "Searching required folders for initialNodesPk ${CYAN}${USE_KEYS[i]}...${NC}"
	for folder in $folders_with_keys; do

	    # Check if the folder hasn't been deleted during the cleanup!
	    if [[ -f "$folder/initialNodesSk.pem" ]]; then

		# Search for matching initialNodesPk's in each folder that contains both pem key files:
		contents_initialNodesSk=$(<"$folder/initialNodesSk.pem")
		if [[ "${USE_KEYS[i]}" == "${contents_initialNodesSk:27:12}" ]]; then
			# If the pem key files for $USE_KEYS[i] are found in $folder, then...
			# Create a new default node structure for $USE_KEYS[i] if it does not yet exist,
			# avoiding a cp `are the same file` error:
			mkdir -p ${default_node_folder[i]}/config
			if [[ "$folder" != "${default_node_folder[i]}/config" ]]; then
				cp $folder/initial{Nodes,Balances}Sk.pem ${default_node_folder[i]}/config
			fi

			# Check if the pem key files reside in a node folder structure with any of the required folders:
			use_keys_db="$(dirname $folder)/db"
			use_keys_logs="$(dirname $folder)/logs"
			use_keys_stats="$(dirname $folder)/stats"

			# Clean up folders in the default node folder structure that are not required:
			if [[ "${KEEPDB_KEYS[i]^^}" == "NO" && -d ${default_node_folder[i]}/db ]]; then

				if [[ ${are_you_sure[i]} == "y" ]]; then
					echo "Removing the /db folder for initialNodesPk ${USE_KEYS[i]}..."
					sudo rm -rf ${default_node_folder[i]}/db
				else
					echo -n "Despite the settings in nodes_config.sh, keeping the /db "
					echo "folder for initialNodesPk ${USE_KEYS[i]}..."
				fi
			fi
			if [[ "${KEEPLOGS_KEYS[i]^^}" == "NO" && -d ${default_node_folder[i]}/logs ]]; then
				sudo rm -rf ${default_node_folder[i]}/logs	# confirmation not needed for /logs
			fi
			if [[ "${KEEPSTATS_KEYS[i]^^}" == "NO" && -d ${default_node_folder[i]}/stats ]]; then
				sudo rm -rf ${default_node_folder[i]}/stats	# confirmation not needed for /stats
			fi


			if [[ ( "${KEEPDB_KEYS[i]^^}" != "NO" && -d "$use_keys_db" ) || \
			      ( "${KEEPLOGS_KEYS[i]^^}" != "NO" && -d "$use_keys_logs" ) || \
			      ( "${KEEPSTATS_KEYS[i]^^}" != "NO" && -d "$use_keys_stats" ) ]]; then
				# If the pem key files for $USE_KEYS[i] reside in a node folder structure where at
				# least one of the required ../db, ../logs, ../stats subfolders for $USE_KEYS[i] exists,
				# then copy the existing node subfolder(s) to $default_node_folder[i].

				mainfolder_existing_node[i]="$(dirname $folder)"
				echo -e -n "${GREEN}Found${NC} required node subfolders for initialNodesPk ${USE_KEYS[i]}... "
				echo -e "in ${mainfolder_existing_node[i]}."

				if [[ "${mainfolder_existing_node[i]}" != "${default_node_folder[i]}" ]]; then
					# Do not copy to self.

					echo -e -n "Moving required node subfolders from ${mainfolder_existing_node[i]} to "
					echo "${default_node_folder[i]}."

					# Move the required data that were found to the $default_node_folder[i] structure:
					if [[ "${KEEPDB_KEYS[i]^^}" != "NO" && -d "$use_keys_db" ]]; then
						sudo mv -u ${mainfolder_existing_node[i]}/db ${default_node_folder[i]}
					fi
					if [[ "${KEEPLOGS_KEYS[i]^^}" != "NO" && -d "$use_keys_logs" ]]; then
						sudo mv -u ${mainfolder_existing_node[i]}/logs ${default_node_folder[i]}
					fi
					if [[ "${KEEPSTATS_KEYS[i]^^}" != "NO" && -d "$use_keys_stats" ]]; then
						sudo mv -u ${mainfolder_existing_node[i]}/stats ${default_node_folder[i]}
					fi
				fi
			fi
		fi
	    fi
	done
done

for i in "${!USE_KEYS[@]}"; do
	# Copy fresh elrond-config to the node config folder and insert friendly node names in prefs.toml:
	cp -f $ELROND_FOLDER/elrond-config/*.* ${default_node_folder[i]}/config

	if [ ! "${NODE_NAMES[i]}" == "" ]; then
	    sed -i 's|NodeDisplayName = ""|NodeDisplayName = "'"${NODE_NAMES[i]}"'"|g' ${default_node_folder[i]}/config/prefs.toml
	fi


	# Copy fresh node binary to $default_node_folder[i]:
	cp -f $ELROND_FOLDER/elrond-go/cmd/node/node ${default_node_folder[i]}
done

# Restart the nodes
bash $scripts_folder/start_nodes_tmux.sh
