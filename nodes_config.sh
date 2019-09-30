#!/bin/bash

# This general configuration script is meant to be sourced at the beginning of other scripts.

# Exit script immediately on error:
set -e

# Define screen colors:
RED='\x1B[0;31m'; CYAN='\x1B[0;36m'; GREEN='\x1B[0;32m'; NC='\x1B[0m'

# Set $GOPATH if not set and export to ~/.profile along with Go binary path:
if [[ $GOPATH=="" ]]; then GOPATH="$HOME/go"; fi
if [[ "$(sed '\|export PATH=\$PATH:/usr/local/go/bin|h;g;$!d' ~/.profile)" == "" ]]; then
	echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile; fi
if [[ "$(sed '/export GOPATH=/h;g;$!d' ~/.profile)" != "export GOPATH=$GOPATH" ]]; then
	echo "export GOPATH=$GOPATH" >> ~/.profile; fi
source ~/.profile

# Use default setup according to ElrondNetwork/elrond-go-scripts repository:
ELROND_FOLDER="$GOPATH/src/github.com/ElrondNetwork"
SOURCE_ELRONDCONFIG_FOLDER="$ELROND_FOLDER/elrond-config"
SOURCE_ELRONDGO_FOLDER="$ELROND_FOLDER/elrond-go"
NODE_FOLDER_PREFIX="$ELROND_FOLDER/elrond-go-node-"	# this will be followed by $USE_KEYS[i]

# Use latest releases of the ElrondNetwork/elrond-go and ElrondNetwork/elrond-config repos on Github:
ELRONDGO_VER="tags/$(curl --silent "https://api.github.com/repos/ElrondNetwork/elrond-go/releases/latest" \
		| grep -Po '"tag_name": "\K.*?(?=")')"
ELRONDCONFIG_VER="tags/$(curl --silent "https://api.github.com/repos/ElrondNetwork/elrond-config/releases/latest" \
		| grep -Po '"tag_name": "\K.*?(?=")')"

# Other settings:
SESSION_PREFIX='node-'	# terminal multiplexer sessions will be named `node-01` and so on

##################################################################################
##          !!!             EDIT BELOW WHERE NECESSARY             !!!          ##
##################################################################################

# Define where the backup pem key files for each node are (to be) stored.
# Make sure the pem files for each node are stored in $BACKUP_ALL_KEYS_FOLDER/xxxxxxxxxxxx
# where xxxxxxxxxxxx are the first 12 characters of the initialNodesPk's for the pem keys pair.
BACKUP_ALLKEYS_FOLDER="$HOME/elrond_backup_keys"	# where are the pem key files for each node stored?

# Define the nodes you want to run, $NODE_NAMES should be array of $NUMBER_OF_NODES strings.
NUMBER_OF_NODES=3
NODE_NAMES=('your_name (1)' 'your_name (2)' 'your_name (3)')

# Define a $USE_KEYS array with the first 12 characters of the initialNodesPk's that should be re-used.
# For updating nodes, the number of elements in $USE_KEYS would normally equal $NUMBER_OF_NODES, but...
# if $NUMBER_OF_NODES > ${#USE_KEYS[@]}, then new pem key files will be created for the remaining nodes
# and these new pem key files will also be backed up in the $BACKUP_ALLKEYS_FOLDER.
# If the keys in $USE_KEYS are not found in the $BACKUP_ALLKEYS_FOLDER, then they will be searched
# in the existing node folders and copied to $BACKUP_ALLKEYS_FOLDER if necessary.
# The $KEEP..._KEYS arrays are parallel arrays, meaning their index corresponds with $USE_KEYS
USE_KEYS=(initNodes1Pk initNodes2Pk initNodes3Pk)	# array with first 12 chars of initialNodesPk's to be used
KEEPDB_KEYS=(yes yes yes)				# keep existing /db folders? (for new testnet launch: no)
KEEPLOGS_KEYS=(no no no)				# keep existing /logs folders? (default: no)
KEEPSTATS_KEYS=(no no no)				# keep existing /stats folders? (default: no)

# Remove all unused node folder structures within $ELROND_FOLDER, if they are found?
# This could free disk space but if you are unsure, set CLEANUP=no.
CLEANUP=yes
