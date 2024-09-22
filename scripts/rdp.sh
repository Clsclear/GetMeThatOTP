#!/bin/bash

# Set default values
chrome_remote_desktop_url="https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb"
username="iamunicode"
password="IAMthatIAM@7"

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
    expect -c "
        spawn sudo dpkg --install $(basename $package_url)
        expect {
            \"*?*\" { send \"\r\"; exp_continue }
        }
    "
    log "Fixing broken dependencies"
    expect -c "
        spawn sudo apt-get install --fix-broken -y
        expect {
            \"*?*\" { send \"\r\"; exp_continue }
        }
    "
    rm $(basename $package_url)
}

# Installation steps
log "Starting installation"

# Create user
log "Creating user '$username'"
sudo useradd -m "$username"
echo "$username:$password" | sudo chpasswd
sudo sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd

# Install Chrome Remote Desktop
install_package "$chrome_remote_desktop_url"

# Install XFCE desktop environment
log "Installing XFCE desktop environment"
expect -c "
    spawn sudo DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes -y xfce4 desktop-base dbus-x11 xscreensaver
    expect {
        \"*?*\" { send \"\r\"; exp_continue }
    }
"

# Set up Chrome Remote Desktop session
log "Setting up Chrome Remote Desktop session"
sudo bash -c 'echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session'

# Disable lightdm service
log "Disabling lightdm service"
sudo systemctl disable lightdm.service

# Install Firefox ESR
expect -c "
    spawn sudo apt update
    expect {
        \"*?*\" { send \"\r\"; exp_continue }
    }
"
expect -c "
    spawn sudo apt install firefox -y
    expect {
        \"*?*\" { send \"\r\"; exp_continue }
    }
"
log "Installation completed successfully"
