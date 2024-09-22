#!/bin/bash

# Set default values
chrome_remote_desktop_url="https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb"

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Function to install packages
install_package() {
    package_url=$1
    log "Downloading $package_url"
    wget -q --show-progress "$package_url"
    log "Installing $(basename $package_url)"
    sudo dpkg --install $(basename $package_url)
    log "Fixing broken dependencies"
    sudo apt-get install --fix-broken -y
    rm $(basename $package_url)
}

# Function to get username from user
get_username() {
    while true; do
        read -p "Enter username: " username
        if [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
            break
        else
            echo "Invalid username. Please use only lowercase letters, numbers, underscores, and hyphens."
        fi
    done
}

# Function to get password from user with confirmation
get_password() {
    while true; do
        read -s -p "Enter password for user $username: " password
        echo
        read -s -p "Confirm password: " password_confirm
        echo
        if [ "$password" = "$password_confirm" ]; then
            if [ ${#password} -ge 8 ]; then
                break
            else
                echo "Password must be at least 8 characters long. Please try again."
            fi
        else
            echo "Passwords do not match. Please try again."
        fi
    done
}

# Installation steps
log "Starting installation"

# Get username and password from user
get_username
get_password

# Create user
log "Creating user '$username'"
sudo useradd -m "$username"
echo "$username:$password" | sudo chpasswd
sudo sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd

# Install Chrome Remote Desktop
install_package "$chrome_remote_desktop_url"

# Install XFCE desktop environment
log "Installing XFCE desktop environment"
sudo DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes -y xfce4 desktop-base dbus-x11 xscreensaver

# Set up Chrome Remote Desktop session
log "Setting up Chrome Remote Desktop session"
sudo bash -c 'echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session'

# Disable lightdm service
log "Disabling lightdm service"
sudo systemctl disable lightdm.service

# Install Firefox ESR
sudo apt update
sudo apt install firefox
log "Installation completed successfully"
