PACKAGES=(
    wine
    wine-mono
    wine-gecko
    gamemode
    lib32-gamemode
    wps-office
    ttf-wps-fonts
    virtualbox
    obs-studio
    qittorrent
    visual-studio-code-bin
    vlc
    seahorse
    htop
    neofetch
    virtualbox-guest-iso
    tlp
    tlp-rdw
    vkd3d
    lib32-vkd3d
    gnome-disk-utility
)

# Update the package database
sudo pacman -Sy

# Loop through the list of packages
for PACKAGE in "${PACKAGES[@]}"; do
    if ! pacman -Qq "$PACKAGE" > /dev/null; then
        echo "Installing $PACKAGE..."
        sudo pacman -S --noconfirm "$PACKAGE"
    else
        echo "$PACKAGE is already installed."
    fi
done


is_installed() {
    pacman -Qq "$1" > /dev/null 2>&1
}

# Function to check if a package is available in the repositories
is_available() {
    pacman -Ss "$1" | grep -q "^$1"
}

# Check if localsend is available in the system's repositories
if is_available "localsend"; then
    echo "Installing localsend from the system's repositories..."
    sudo pacman -S --noconfirm localsend
else
    echo "localsend not found in the system's repositories. Checking for localsend-git..."

    # Check if localsend-git is available in the Chaotic AUR
    if is_available "localsend-git"; then
        echo "Installing localsend-git from the Chaotic AUR..."
        sudo pacman -S --noconfirm localsend-git
    else
        echo "localsend-git not found in the Chaotic AUR. Please check your repository settings."
        exit 1
    fi
fi



stacer="http://archlinuxgr.tiven.org/archlinux/x86_64/stacer-1.1.0-1-x86_64.pkg.tar.zst"

FILE_NAME=$(basename "$stacer")

wget "$stacer"

sudo pacman -U "$FILE_NAME"

sudo rm "$FILE_NAME"

FILE_URL="https://github.com/subhra74/xdm/releases/download/8.0.29/xdman_gtk-8.0.29-1-x86_64.pkg.tar.zst"

# Get the file name from the URL
FILE_NAME=$(basename "$FILE_URL")

# Download the file
echo "Downloading $FILE_NAME..."
wget "$FILE_URL"

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo "Download failed. Exiting."
    exit 1
fi

# Install the package using pacman
echo "Installing $FILE_NAME..."
sudo pacman -U --noconfirm "$FILE_NAME"

# Check if the installation was successful
if [ $? -ne 0 ]; then
    echo "Installation failed. Exiting."
    exit 1
fi

# Delete the downloaded file
echo "Deleting $FILE_NAME..."
rm "$FILE_NAME"
