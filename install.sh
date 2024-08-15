#!/bin/bash
########################
# Author: Rocklin K S
# Date: 13/08/2024
# This script makes my config to autinstall
# Version: v1
############################


set -exo  pipefail
#Check if yay is installed
if ! command -v yay &> /dev/null; then
    sudo pacman -S yay --noconfirm
fi

# Function to check and add chaotic-aur repo
if ! grep -q "chaotic-aur" /etc/pacman.conf; then
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
fi
PACMAN="/etc/pacman.conf"
CHAOTIC="[chaotic-aur]"
INCLUDE_LINE="Include = /etc/pacman.d/chaotic-mirrorlist"

# Check if the section already exists in the file
if ! grep -q "$CHAOTIC_AUR_SECTION" "$PACMAN"; then
#     Add the section to the end of the file
    echo -e "\n$CHAOTIC\n$INCLUDE_LINE" >> "$PACMAN"
    echo "Added $CHAOTIC and $INCLUDE_LINE to $PACMAN."
else
    echo "$CHAOTIC already exists in $PACMAN."
fi

sudo pacman -Syu --noconfirm
# Define the list of packages to install
packages=(
    zramswap preload python-dbus auto-cpufreq
    xfce4-panel polkit-gnome xfdesktop blueman
    xfce4-settings xfce4-power-manager xfce4-docklike-plugin
    bc openbox obconf playerctl picom parcellite
    numlockx rofi polybar lxappearance betterlockscreen
    zsh zsh-syntax-highlighting zsh-autosuggestions
    zsh-history-substring-search zsh-completions
)

# Install the packages if they are not already installed
for package in "${packages[@]}"; do
    if ! pacman -Q "$package" &> /dev/null; then
        sudo pacman -S "$package" --noconfirm
    else
        echo "$package is already installed. Skipping."
    fi
done

##Services to Enbale
sudo systemctl enable --now bluetooth
sudo systemctl enable --now preload

## Move the betterlock folder
sudo mv -f cache/* "$HOME/.cache/"

# Copy the backlight rules file, forcing the overwrite
sudo mv -f udev/rules.d/90-backlight.rules /etc/udev/rules.d/

# Copy the networkmanager_dmenu file, forcing the overwrite
sudo mv -f usr/bin/networkmanager_dmenu /usr/bin/
sudo chmod +x /usr/bin/networkmanager_dmenu

sudo mv -f Fonts/ /usr/share/fonts/
sudo fc-cache -fv

# Create the zsh directory and extract the contents of zsh.tar.gz
mkdir -p zsh
tar -xzvf zsh.tar.gz -C zsh
sudo mv -f zsh/.bashrc $HOME/.bashrc
sudo mv -f zsh/.zshrc $HOME/.zshrc

# Check if the betterlockscreen cache directory exists and has the correct permissions
if [ -d "$HOME/.cache/betterlockscreen" ]; then
    if [ "$(stat -c '%U:%G' "$HOME/.cache/betterlockscreen")" != "root:$(id -gn)" ] || [ "$(stat -c '%a' "$HOME/.cache/betterlockscreen")" != "750" ]; then
        sudo chown root:$(id -gn) "$HOME/.cache/betterlockscreen"
        sudo chmod 750 "$HOME/.cache/betterlockscreen"
 
    else
        echo "Permissions for $HOME/.cache/betterlockscreen are already correct. Skipping."
    fi
else
    echo "$HOME/.cache/betterlockscreen directory does not exist. Skipping permission update."
fi

## Set the permissions for the .config
sudo chown -R root:$(id -gn) "$HOME/.config"
chmod -R 770 "$HOME/.config"

## Move the Config files and set the network
sudo mv -f config/* $HOME/.config/
sudo chmod +x $HOME/.config/polybar/scripts/*
CONFIG="$HOME/.config/polybar/config.ini"

ETHERNET=$(ip link | awk '/state UP/ {print $2}' | tr -d :)
WIFI=$(ip link | awk '/state UP/ {print $2}' | tr -d : | grep -i '^wl')

if [ -n "$WIFI" ]; then
    sed -i "s/sys_network_interface = wlan0/sys_network_interface = $WIFI/" "$CONFIG"
elif [ -n "$ETHERNET" ]; then
    sed -i "s/sys_network_interface = wlan0/sys_network_interface = $ETHERNET/" "$CONFIG"
fi
