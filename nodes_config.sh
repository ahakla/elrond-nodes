#!/bin/bash

# this general configuration script is meant to be sourced at the beginning of other scripts

# exit script immediately on error
set -e

# define screen colors
RED='\x1B[0;31m'; CYAN='\x1B[0;36m'; GREEN='\x1B[0;32m'; NC='\x1B[0m'

# set $GOPATH if not set and export to ~/.profile along with Go binary path
if [[ $GOPATH=="" ]]; then
	GOPATH="$HOME/go"
fi
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile
echo "export GOPATH=$GOPATH" >> ~/.profile
source ~/.profile

# use default setup according to ElrondNetwork/elrond-go-scripts repository
ELROND_FOLDER="$GOPATH/src/github.com/ElrondNetwork"
SOURCE_ELRONDCONFIG_FOLDER="$ELROND_FOLDER/elrond-config"
SOURCE_ELRONDGO_FOLDER="$ELROND_FOLDER/elrond-go"
NODE_FOLDER_PREFIX="$ELROND_FOLDER/elrond-go-node-"  # this will be followed by $USE_KEYS[i]

# use the latest releases of the ElrondNetwork/elrond-go and ElrondNetwork/elrond-config repos on Github
ELRONDGO_VER="tags/$(curl --silent "https://api.github.com/repos/ElrondNetwork/elrond-go/releases/latest" \
		| grep -Po '"tag_name": "\K.*?(?=")')"
ELRONDCONFIG_VER="tags/$(curl --silent "https://api.github.com/repos/ElrondNetwork/elrond-config/releases/latest" \
		| grep -Po '"tag_name": "\K.*?(?=")')"

# other settings
SESSION_PREFIX='node-'			# terminal multiplexer sessions will be named `node-01` and so on

##################################################################################
##                          EDIT BELOW WHERE NECESSARY                          ##
##################################################################################

# define where the backup pem key files for each node are (to be) stored
# make sure the pem files for each node are stored in $BACKUP_ALL_KEYS_FOLDER/xxxxxxxxxxxx
# where xxxxxxxxxxxx are the first 12 characters of the initialNodesPk's for the pem keys pair
BACKUP_ALLKEYS_FOLDER="$HOME/elrond_backup_keys"	# where are the pem key files for each node stored?

# define the nodes you want to run
NUMBER_OF_NODES=2
NODE_NAMES=('Mystic1' 'Mystic2')	# the array size should correspond with $NUMBER_OF_NODES

# define a $USE_KEYS array with the first 12 characters of the initialNodesPk's that should be re-used
# normally, the number of elements in $USE_KEYS would equal $NUMBER_OF_NODES, but...
# if ${#USE_KEYS[@]} > $NUMBER_OF_NODES, then only the first $NUMBER_OF_NODES elements of $USE_KEYS are used
# if ${#USE_KEYS[@]} < $NUMBER_OF_NODES, then new pem key files will be created for the remaining nodes
# these new pem key files will also be backed up in the $BACKUP_ALLKEYS_FOLDER
# if the keys in $USE_KEYS are not found in the $BACKUP_ALLKEYS_FOLDER, they will be searched
# in the existing node folders and copied to $BACKUP_ALLKEYS_FOLDER if necessary
# the $KEEP..._KEYS arrays are parallel arrays, meaning their index corresponds with $USE_KEYS
USE_KEYS=(4ec8b4269c28 7850694d20c7)		# use these existing pem key files (first 12 chars of initialNodesPk)
KEEPDB_KEYS=(no no)				# keep existing /db folders? (default: yes)
KEEPLOGS_KEYS=(no no)				# keep existing /logs folders? (default: no)
KEEPSTATS_KEYS=(no no)				# keep existing /stats folders? (default: no)

# remove all unused node folder structures within $ELROND_FOLDER, if they are found?
# this could free unused disk space but if you are unsure, set CLEANUP=no
CLEANUP=yes
