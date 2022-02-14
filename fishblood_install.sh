#!/bin/bash

## Config
NS_URL="https://your_nightscout_server.com"	                # Nightscout instance URL
updateInt="1"                                               # Update interval in minutes
bloodFile="/tmp/blood"		                                # Location to store updated values
promptFile="/usr/share/fish/functions/prompt_login.fish"    # Fish prompt file to be modified
xUser=$USER

echo -e "\n[+] Fishblood - elGumso 2022"
echo "[+] Installation script."

## Install deps
echo -e "\n[+] Installing dependencies..."
sudo apt install jq -y

## Install latest version of Fish
# sudo apt-add-repository ppa:fish-shell/release-3
# sudo apt update
# sudo apt install fish

## Setup Crontab to update Bloodsugar values
echo -e "\n[+] Setting up Crontab for user $xUser"
(crontab -l; echo "*/$updateInt * * * * curl -s $NS_URL/pebble | jq -r '.bgs | .[] | [.sgv, .direction, .bgdelta] | @tsv' | sed 's|\"||g' > $bloodFile") |awk '!x[$0]++'|crontab -

# Backup Fish prompt file
echo "[+] Backing up Fish prompt file - $promptFile"
cp /usr/share/fish/functions/prompt_login.fish ~/.prompt_login.fish
echo "[+] Fish prompt file backed up at ~/.prompt_login.fish"

## Check if modified prompt already installed
echo -e "\n[+] Checking if Fishblood has been configured previously..."
if grep -Fq "cat /tmp/blood" $promptFile
then
    echo -e "[+] Fishblood has already been configured in $promptFile"
else
    ## Modify Fish Shell prompt
    echo "[+] Modifying Fish login prompt..."
    sudo sed -i "s%echo -n -s (set_color \$fish_color_user) \"\$USER\" (set_color normal) @ (set_color \$color_host) (prompt_hostname) (set_color normal)%echo -n -s (set_color \$fish_color_user) \"\$USER\" (set_color normal) @ (set_color \$color_host) (prompt_hostname) (set_color normal) '\ \-\-\> ' \ (set_color \$fish_color_host_remote) (cat /tmp/blood | awk '{print \$1}') (set_color normal) '\ ' \{(cat /tmp/blood | awk '{print \$3}')\}%" \
    $promptFile
fi

echo -e "\n[+] Fishblood hopefully configured!\n"