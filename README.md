# elrond-nodes

This repository enables you to install/update, and monitor one or multiple Elrond nodes on Ubuntu 18.04.
For a Medium post about how to use this repository, see
https://medium.com/@haklander/run-and-maintain-one-or-multiple-elrond-nodes-in-ubuntu-18-04-5f5c9658e580

### Installation

Instructions for using this repository:
 * always have a safe backup for all your pem key files!
 * if you already have nodes, create a separate subfolder for each node identity in `$HOME/elrond_backup_keys`,
(like `$HOME/elrond_backup_keys/node1` and `$HOME/elrond_backup_keys/node2`), and copy your `initialNodesSk.pem`
and `initialBalancesSk.pem` there

 * `cd; git clone https://github.com/ahakla/elrond-nodes.git` - clone this repository
 * `cd elrond-nodes` - open the folder with the scripts
 * `nano nodes_config.sh` - customize the nodes setup
 * stop all nodes, if they are still running (for tmux you may want to use `tmux kill-server`)
 * `bash install_nodes.sh` - (re-)install the Elrond node(s)
 * `bash start_nodes_tmux.sh` to run all nodes that were specified in `nodes_config.sh`

### Configuration of nodes_config.sh

You can use this repo for different scenarios:

1. You have never run an Elrond node before and you want to run `NUMBER_OF_NODES` on one machine.

2. You have run one or more Elrond nodes before, and you just want to re-use the key identities.

3. Same as 2, but you want to run additional nodes.

4. Same as 2, but you don't want to re-use all key identities.

5. Same as 4, and you want to run additional nodes. 

----------------------------------------------------------

Here is how you could setup your `nodes_config.sh` in these scenario's, prior to running `install_nodes.sh`. 
**Always carefully review all the settings below `!!! EDIT BELOW WHERE NECESSARY !!!`.**

1. Set `USE_KEYS=()`. For clarity, it's best to also do `RESTAPI_KEYS=()`, `KEEPDB_KEYS=()`, `KEEPLOGS_KEYS=()`,
`KEEPSTATS_KEYS=()`.

2. You will probably have registered the initialNodesPk and the initialBalancesPk. Suppose you had two nodes
for which the first 12 characters (key-id's) in initialNodesPk were 86001ab0d380 and 22a5a948582d. Then you set
`NUMBER_OF_NODES=2` and `NODE_NAMES=('your_name (1)' 'your_name (2)')`, or any other friendly node names you
would like to give your nodes. You set the array `USE_KEYS=(86001ab0d380 22a5a948582d)`, and if you want to keep
the nodes' databases to not have to synchronize again (unless there is a new testnet), you can set the array
`KEEPDB_KEYS=(yes yes)`, for the rest the default is `RESTAPI_KEYS=(yes yes)`, `KEEPLOGS_KEYS=(no no)`, and `KEEPSTATS_KEYS=(no no)`.

3. Same as 2, but now you set `NUMBER_OF_NODES` higher than the number of elements in the `USE_KEYS`, `RESTAPI_KEYS`, `KEEPDB_KEYS`,
`KEEPLOGS_KEYS`, and `KEEPSTATS_KEYS` arrays. Make sure that `NODE_NAMES` contains `NUMBER_OF_NODES` elements.
The `install_nodes.sh` script will create new node identities and back up their pem key files.
Also, `nodes_config.sh` will be automatically updated to the new configuration.

4. Just leave out the array entries for the key-id you don't want to use in the `USE_KEYS`, `RESTAPI_KEYS`, `KEEPDB_KEYS`,
`KEEPLOGS_KEYS`, and `KEEPSTATS_KEYS` arrays. Make sure that `NODE_NAMES` contains the same number of elements
as `USE_KEYS` and `NUMBER_OF_NODES`.

5. Same as 4, but now you set `NUMBER_OF_NODES` higher than the number of elements in the `USE_KEYS`, `RESTAPI_KEYS`, `KEEPDB_KEYS`,
`KEEPLOGS_KEYS`, and `KEEPSTATS_KEYS` arrays. Make sure that `NODE_NAMES` contains `NUMBER_OF_NODES` elements.
The `install_nodes.sh` script will create new node identities and back up their pem key files.
Also, `nodes_config.sh` will be automatically updated to the new configuration.

----------------------------------------------------------

### Running the nodes

Use `bash start_nodes_tmux.sh` or `bash start_nodes_screen.sh` for this, respectively.
You can choose to run all node instances using `tmux` or `screen` as a terminal multiplexer.

NOTE: The `RESTAPI_KEYS` setting will be `yes` by default. The first node will use REST-API port 8080,
the second node 8081, and so on. However, this will make your nodes vulnerable if you don't close these
REST-API ports with `ufw`, otherwise someone could remotely do REST-API calls to your nodes!
