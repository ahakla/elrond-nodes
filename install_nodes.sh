#!/bin/bash

# this installation script will make a clean install for $NUMBER_OF_NODES nodes

# exit script immediately on error
set -e

# source the general node config file, which should be in the same folder as the current script
source ./nodes_config.sh
scripts_folder=$PWD

# first check if the user has stopped all their nodes
stopped_nodes_answer=""		# initialize as empty
while [[  $stopped_nodes_answer != "y" && $stopped_nodes_answer != "exit" ]] ; do
	read -p "Have you stopped all node instances? [y/exit] : " stopped_nodes_answer

	if [[ $stopped_nodes_answer == "exit" ]] ; then
		echo -e "${RED}Please stop all node instances first!${NC} E.g., use 'tmux kill-server'. Exiting script."
		exit

	elif [[ $stopped_nodes_answer != "y" ]] ; then
		echo -e "${RED}Please answer \"y\" or \"exit\".${NC} Repeating the question."
	fi
done

# then check if the user has customized nodes_config.sh
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

# create $ELROND_FOLDER and $BACKUP_ALLKEYS_FOLDER if they do not exist
mkdir -p $ELROND_FOLDER $BACKUP_ALLKEYS_FOLDER

# recursively search $ELROND_FOLDER and $BACKUP_ALL_KEYS_FOLDER for folders that contain
# both pem key files and put them in a string of strings called $folders_with_keys,
# excluding subfolders of the elrond-config and elrond-go repos
folders_with_keys=$(find $ELROND_FOLDER $BACKUP_ALLKEYS_FOLDER -type d \
		-not -path "$SOURCE_ELRONDCONFIG_FOLDER/*" -not -path "$SOURCE_ELRONDGO_FOLDER/*" \
		-exec test -f '{}'/initialNodesSk.pem -a -f '{}'/initialBalancesSk.pem \; -print)

# to be safe, back up all the keys that have been found in $folders_with_keys to $BACKUP_ALLKEYS_FOLDER
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

for i in "${!USE_KEYS[@]}"; do
	# $mainfolder_existing_node[i] is folder where pem key files for $USE_KEYS[i] are found...
	# ...and for which all the required ../db ../logs ../stats folders exist
	mainfolder_existing_node[i]=""	# initialize at ""

	# keys_found is "yes" as soon as the pem key files for $USE_KEYS[i] are found
	keys_found="no"			# initialize at "no"

	default_backup_keys_folder[i]="$BACKUP_ALLKEYS_FOLDER/${USE_KEYS[i]}"  # default backup folder for $USE_KEYS[i]
	default_node_folder[i]="$NODE_FOLDER_PREFIX${USE_KEYS[i]}"  # default node folder for $USE_KEYS[i]

	echo
	echo -e "Searching pem key files and required folders for initialNodesPk ${CYAN}${USE_KEYS[i]}..."
	for folder in $folders_with_keys; do

		# search for matching initialNodesPk's in each folder that contains both pem key files
		contents_initialNodesSk=$(<"$folder/initialNodesSk.pem")
		if [[ "${USE_KEYS[i]}" == "${contents_initialNodesSk:27:12}" ]]; then

			# if the pem key files for $USE_KEYS[i] are found in $folder
			keys_found="yes"

			# create a new default node structure for $USE_KEYS[i] if it does not yet exist,
			# avoiding a cp `are the same file` error
			mkdir -p ${default_node_folder[i]}/config
			if [[ "$folder" != "${default_node_folder[i]}/config" ]]; then
				cp $folder/initial{Nodes,Balances}Sk.pem ${default_node_folder[i]}/config
			fi

			# now check if the pem key files reside in a node folder structure with any of the required folders
			use_keys_db="$(dirname $folder)/db"
			use_keys_logs="$(dirname $folder)/logs"
			use_keys_stats="$(dirname $folder)/stats"

			# clean up folders in the default node folder structure that are not required
			if [[ "${KEEPDB_KEYS[i]^^}" == "NO" && -d ${default_node_folder[i]}/db ]]; then
				echo -n "Are you sure you want to remove the /db folder for initialNodesPk "
				read -p "${USE_KEYS[i]}...? [y/n] : " are_you_sure
				if [[ $are_you_sure == "y" ]]; then
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
				# if the pem key files for $USE_KEYS[i] reside in a node folder structure where at
				# least one of the required ../db, ../logs, ../stats subfolders for $USE_KEYS[i] exists,
				# then copy the existing node subfolder(s) to $default_node_folder[i]

				mainfolder_existing_node[i]="$(dirname $folder)"
				echo -e -n "${GREEN}Found${NC} required node subfolders for initialNodesPk ${USE_KEYS[i]}... "
				echo -e "in ${mainfolder_existing_node[i]}."

				if [[ "${mainfolder_existing_node[i]}" != "${default_node_folder[i]}" ]]; then
					# do not copy to self
					echo -e -n "Moving required node subfolders from ${mainfolder_existing_node[i]} to "
					echo "${default_node_folder[i]}."

					# move the required data to the $default_node_folder[i] structure
					# clean up if folders are not required, ask for confirmation before removing /db folder
					if [[ "${KEEPDB_KEYS[i]^^}" != "NO" && -d "$use_keys_db" ]]; then
						sudo mv -nu ${mainfolder_existing_node[i]}/db ${default_node_folder[i]}
					fi
					if [[ "${KEEPLOGS_KEYS[i]^^}" != "NO" && -d "$use_keys_logs" ]]; then
						sudo mv -nu ${mainfolder_existing_node[i]}/logs ${default_node_folder[i]}
					fi
					if [[ "${KEEPSTATS_KEYS[i]^^}" != "NO" && -d "$use_keys_stats" ]]; then
						sudo mv -nu ${mainfolder_existing_node[i]}/stats ${default_node_folder[i]}
					fi
				fi
			fi
		fi
	done

	if [[ $keys_found == "no" ]]; then
		# if the pem key files for $USE_KEYS[i] can't be found anywhere
		echo -e "${RED}Could not find${NC} pem key files for initialNodesPk ${USE_KEYS[i]}... anywhere!"
		echo -e "${RED}Please re-customize nodes_config.sh!${NC} Exiting script."
		exit
	fi
done

if [[ "${CLEANUP^^}" == "YES" ]]; then
	# clean up
	# remove all $folders_with_keys, except for $BACKUP_ALLKEYS_FOLDER and $default_node_folder[i]
	# if the folder basename is config, then recursively remove the parent folder too, assuming a node folder structure

	for folder in $folders_with_keys; do

		match=0
		for i in "${!USE_KEYS[@]}"; do
		 	if [[ "$folder" == "${default_backup_keys_folder[i]}" ||  "$folder" == "${default_node_folder[i]}/config" ]]; then
				# if the pem keys in $folder reside in $default_backup_keys_folder[i] or
				# $default_node_folder[i]/config for any of the $USE_KEY[i],
				# then do not remove $folder
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
				read -p "Are you sure you want to recursively remove the folder $rm_folder? [y/n] : " are_you_sure
				if [[ $are_you_sure == "y" ]]; then
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

# setup
# making sure the distro is up-to-date
sudo apt update && sudo apt dist-upgrade -y

# install some dependencies
sudo apt install -y git curl screen tmux

# check if go is already installed
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

# clean up old installations
if [[ -d $SOURCE_ELRONDGO_FOLDER ]]; then
	sudo rm -rf $SOURCE_ELRONDGO_FOLDER
fi
if [[ -d $SOURCE_ELRONDCONFIG_FOLDER ]]; then
	sudo rm -rf $SOURCE_ELRONDCONFIG_FOLDER
fi

cd $ELROND_FOLDER

# clone the elrond-go & elrond-config repos
git clone https://github.com/ElrondNetwork/elrond-go
cd $SOURCE_ELRONDGO_FOLDER && git checkout --force $ELRONDGO_VER
cd $ELROND_FOLDER
git clone https://github.com/ElrondNetwork/elrond-config
cd $SOURCE_ELRONDCONFIG_FOLDER && git checkout --force $ELRONDCONFIG_VER

# copy fresh elrond-config to the node config folder
# and insert friendly node names in config.toml
for i in "${!USE_KEYS[@]}"; do
	cp $SOURCE_ELRONDCONFIG_FOLDER/*.* ${default_node_folder[i]}/config

	if [ ! "${NODE_NAMES[i]}" == "" ]; then
	    sed -i 's|NodeDisplayName = ""|NodeDisplayName = "'"${NODE_NAMES[i]}"'"|g' ${default_node_folder[i]}/config/config.toml
	fi
done

# compile elrond-go
cd $SOURCE_ELRONDGO_FOLDER
GO111MODULE=on go mod vendor
cd $SOURCE_ELRONDGO_FOLDER/cmd/node && go build -i -v -ldflags="-X main.appVersion=$(git describe --tags --long --dirty)"
# copy fresh node binary to $default_node_folder[i]
for i in "${!USE_KEYS[@]}"; do
	# copy fresh elrond-config to the node config folder
	cp $SOURCE_ELRONDGO_FOLDER/cmd/node/node ${default_node_folder[i]}
done

# identity key-gen
cd $SOURCE_ELRONDGO_FOLDER/cmd/keygenerator
go build

# prepare appending settings for the new nodes identities
use_keys_string_new="${USE_KEYS[@]}"
keepdb_keys_string_new="${KEEPDB_KEYS[@]}"
keeplogs_keys_string_new="${KEEPLOGS_KEYS[@]}"
keepstats_keys_string_new="${KEEPSTATS_KEYS[@]}"

# create new pem key files for the remaining nodes and make a backup
number_of_existing_nodes=${#USE_KEYS[@]}
number_of_new_nodes=$((NUMBER_OF_NODES-number_of_existing_nodes))
for new_node in $( seq 0 $((number_of_new_nodes - 1)) ); do
	cd $SOURCE_ELRONDGO_FOLDER/cmd/keygenerator	# just to be sure
	./keygenerator

	contents_initialNodesSk=$(<"initialNodesSk.pem")
	key_id="${contents_initialNodesSk:27:12}"

	# create a backup of the pem key files in $BACKUP_ALLKEYS_FOLDER/$key_id
	mkdir -p "$BACKUP_ALLKEYS_FOLDER/$key_id"
	cp initial{Nodes,Balances}Sk.pem "$BACKUP_ALLKEYS_FOLDER/$key_id"

	default_new_node_folder="$NODE_FOLDER_PREFIX$key_id"  # default node folder for $key_id
	mkdir -p $default_new_node_folder/config
	cp initial{Nodes,Balances}Sk.pem $default_new_node_folder/config

	# appending new node identities to settings
	use_keys_string_new="${use_keys_string_new} $key_id"
	keepdb_keys_string_new="${keepdb_keys_string_new} yes"		# safest default is yes
	keeplogs_keys_string_new="${keeplogs_keys_string_new} no"	# default is no
	keepstats_keys_string_new="${keepstats_keys_string_new} no"	# default is no

	# copy fresh elrond-config to the node config folder
	# and insert friendly node names in config.toml
	cp $SOURCE_ELRONDCONFIG_FOLDER/*.* $default_new_node_folder/config
	i=$((number_of_existing_nodes + new_node))
	if [ ! "${NODE_NAMES[i]}" == "" ]; then
	    sed -i 's|NodeDisplayName = ""|NodeDisplayName = "'"${NODE_NAMES[i]}"'"|g' $default_new_node_folder/config/config.toml
	fi

	# copy fresh node binary to $default_new_node_folder
	cp $SOURCE_ELRONDGO_FOLDER/cmd/node/node $default_new_node_folder
done

# modify ./nodes_config.sh to include new node identities
sed -i 's/^USE_KEYS=([^)]*)/USE_KEYS=('"$use_keys_string_new"')/g' $scripts_folder/nodes_config.sh
sed -i 's/^KEEPDB_KEYS=([^)]*)/KEEPDB_KEYS=('"$keepdb_keys_string_new"')/g' $scripts_folder/nodes_config.sh
sed -i 's/^KEEPLOGS_KEYS=([^)]*)/KEEPLOGS_KEYS=('"$keeplogs_keys_string_new"')/g' $scripts_folder/nodes_config.sh
sed -i 's/^KEEPSTATS_KEYS=([^)]*)/KEEPSTATS_KEYS=('"$keepstats_keys_string_new"')/g' $scripts_folder/nodes_config.sh
