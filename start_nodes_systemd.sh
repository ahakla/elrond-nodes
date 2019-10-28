#!/bin/bash
# Script by https://github.com/koen84/
# This script will run all $NUMBER_OF_NODES nodes in tmux sessions.

# Exit script immediately on error:
set -e

# define extra color
PURPLE='\x1B[0;35m';
YELLOW='\x1B[1;33m';

# Source the general node config file, which should be in the same folder as the current script:
source ./nodes_config.sh

echo -e "\n${RED}WARNING : this script opens the rest API, run a firewall.${NC} For example :"
echo "bash <(https://raw.githubusercontent.com/koen84/Elrond-scripts/master/ufw.sh)"

systemd_status=""

for i in "${!USE_KEYS[@]}"; do
        default_node_folder[i]="$NODE_FOLDER_PREFIX${USE_KEYS[i]}" # default node folder for $USE_KEYS[i]

        suffix="$(printf "%02d" $((i+1)))"
        rest_api_port=$((8080+i))

        if ! [ -f "/lib/systemd/system/elrond-${USE_KEYS[i]}.service" ]; then
                echo -e "\nInstalling new unitfile elrond-$suffix.service linked to elrond-${USE_KEYS[i]}.service"
                unitfile=$( eval "printf \"$(cat elrond.service)\" ")
                sudo sh -c "echo \"$unitfile\" > /lib/systemd/system/elrond-${USE_KEYS[i]}.service"

                if [ -f "/lib/systemd/system/elrond-$suffix.service" ]; then
                        sudo sh -c "rm /lib/systemd/system/elrond-$suffix.service"
                fi

                sudo sh -c "ln -s /lib/systemd/system/elrond-${USE_KEYS[i]}.service /lib/systemd/system/elrond-$suffix.service"
                sudo systemctl daemon-reload
                sudo systemctl enable elrond-$suffix.service
        fi
        sudo systemctl restart elrond-$suffix.service
        sleep 1
        systemd_status+="${PURPLE}elrond-$suffix.service :${NC}\n$(sudo systemctl status elrond-$suffix.service | grep -A1 Loaded)\n"
        sudo chown -R $USER:$USER $NODE_FOLDER_PREFIX${USE_KEYS[i]}
done

echo -e "\n${GREEN}Started${CYAN} $NUMBER_OF_NODES${NC} node instances with systemd."
echo -e "Use ${CYAN}sudo systemctl status elrond-##.service${NC} (## = 01, 02, etc.) to see the node status.\n"
echo
echo -e "${YELLOW}Current status of the nodes fired up by this script :${NC}\n$systemd_status"
