# elrond-nodes

This repository enables you to install/update one or multiple Elrond nodes on Ubuntu 18.04.

### Installation

Instructions for using this repository:
 * always have a safe backup for all your pem key files!
 * if you already have nodes, create a separate subfolder for each node identity in $HOME/elrond_backup_keys, and copy your initialNodesSk.pem and initialBalancesSk.pem there

 * `git clone git@github.com:ahakla/elrond-nodes.git` - clone this repository
 * `cd elrond-nodes` - open the folder with the scripts
 * `nano nodes_config.sh` - customize the nodes setup
 * stop all nodes, if they are still running (for tmux you may want to use `tmux kill-server`)
 * `bash install_nodes.sh - (re-)install the Elrond node(s)
 * `bash start_nodes_tmux.sh` to run all nodes that were specified in `nodes_config.sh`
