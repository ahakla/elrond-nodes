#!/bin/bash

# this general configuration script is meant to be sourced at the beginning of other scripts

# exit script immediately on error
set -e

# define screen colors
RED='\x1B[0;31m'
CYAN='\x1B[0;36m'
GREEN='\x1B[0;32m'
NC='\x1B[0m'

# use default setup according to ElrondNetwork/elrond-go-scripts repository
ELROND_FOLDER="$GOPATH/src/github.com/ElrondNetwork"
SOURCE_ELRONDCONFIG_FOLDER="$ELROND_FOLDER/elrond-config"
SOURCE_ELRONDGO_FOLDER="$ELROND_FOLDER/elrond-go"
NODE_FOLDER_PREFIX="$ELROND_FOLDER/elrond-go-node-"  # this will be followed by $USE_KEYS[i]

# other settings
SESSION_PREFIX='node-'			# terminal multiplexer sessions will be named `node-01` and so on

##################################################################################
##                          EDIT BELOW WHERE NECESSARY                          ##
##################################################################################

# define the code versions to be used
ELRONDGO_VER='tags/v1.0.19'		# see https://github.com/ElrondNetwork/elrond-go/releases/latest
ELRONDGO_BRANCH='master'		# default: 'master', could also by 'development', or another tag
ELRONDCONFIG_VER='tags/testnet-1018'	# see https://github.com/ElrondNetwork/elrond-config/releases/latest
ELRONDCONFIG_BRANCH='master'		# default: 'master', could also by 'development', or another tag

# define where the backup pem key files for each node are (to be) stored
# make sure the pem files for each node are stored in $BACKUP_ALL_KEYS_FOLDER/xxxxxxxxxxxx
# where xxxxxxxxxxxx are the first 12 characters of the initialNodesPk's for the pem keys pair
BACKUP_ALLKEYS_FOLDER="$HOME/elrond_backup_keys"	# where are the pem key files for each node stored?

# define the nodes you want to run
NUMBER_OF_NODES=2
NODE_NAMES=('Alwin (1)' 'Alwin (2)')	# the array size should correspond with $NUMBER_OF_NODES

# define a $USE_KEYS array with the first 12 characters of the initialNodesPk's that should be re-used
# normally, the number of elements in $USE_KEYS would equal $NUMBER_OF_NODES, but...
# if ${#USE_KEYS[@]} > $NUMBER_OF_NODES, then only the first $NUMBER_OF_NODES elements of $USE_KEYS are used
# if ${#USE_KEYS[@]} < $NUMBER_OF_NODES, then new pem key files will be created for the remaining nodes
# these new pem key files will also be backed up in the $BACKUP_ALLKEYS_FOLDER
# if the keys in $USE_KEYS are not found in the $BACKUP_ALLKEYS_FOLDER, they will be searched
# in the existing node folders and copied to $BACKUP_ALLKEYS_FOLDER if necessary
USE_KEYS=(86001ab0d380 22a5a948582d)	# use these existing pem key files (first 12 chars of initialNodesPk)
KEEPDB_KEYS=(no no)			# keep existing /db folders? (default: yes)
KEEPLOGS_KEYS=(no no)			# keep existing /logs folders? (default: no)
KEEPSTATS_KEYS=(no no)			# keep existing /stats folders? (default: no)
CLEANUP=yes				# within $ELROND_FOLDER, remove all unused node folder structures?
