#!/bin/bash
#Check if yay is installed
if ! command -v yay &> /dev/null; then
    sudo pacman -S yay
fi

# Function to check and add chaotic-aur repo
if ! grep -q "chaotic-aur" /etc/pacman.conf; then
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    sudo pacman -Syu
fi

sudo pacman -S xfce4-panel xfdesktop xfce4-settings xfce4-power-manager xfce4-docklike-plugin bc openbox obconf playerctl picom parcellite numlockx rofi polybar lxappearance betterlockscreen

cd cache
sudo cp * ~/.cache/ -rf
cd ..


cd udev/rules.d/
sudo cp 90-backlight.rules /etc/udev/rules.d/

cd usr/bin
sudo chmod +x networkmanager_dmenu
sudo cp networkmanager_dmenu /usr/bin/
cd ..

cd zsh
sudo cp .bash .zsh
~/$HOME 
cd ..

sudo cp config/* ~/.config/
cd ~/.config/polybar/scripts/
sudo chmod +x *
cd ..

cd fonts
tar -xzvf fonts.tar.gz
sudo mv fonts/* /usr/share/fonts/ -rf
sudo fc-cache -fv


