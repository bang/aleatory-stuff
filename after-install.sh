
## installing essential and useful packages
sudo apt install -y vim vim-gtk3 tmux \
git \
build-essential \
vlc \
nmap \
nfs-common

# Removing don't-ask-for-install packages from Linux
# * is not working on zsh, I don't know why!
/bin/bash -c "sudo apt purge -y thunderbird* libreoffice*"


## installing docker according to https://docs.docker.com/engine/install/ubuntu/
# removing possible already installed docker package
sudo apt-get remove docker docker-engine docker.io containerd runc

## installing docker dependecies
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

# adding repos, keys etc
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88

# ubuntu release is passed as argument - TODO improve argument analysis
ubuntu_release=$1
# if argument is not passed, assuming xenial. This will break some day
if [ -z "$ubuntu_release" ]; then
    ubuntu_release="xenial"
fi

# adding docker official repository for Ubuntu
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $ubuntu_release \
   stable"
sudo apt-get update

# finally installing docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Installing brave browser
sudo apt installing -y apt-transport-https curl gnupg
curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -
echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update
sudo apt install -y brave-browser

# installing oh my zsh
sudo apt install -y zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# installing extra fonts for oh my zsh themes
git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
chmod +x install.sh
./install.sh
cd ..
rm -rf fonts

# Installing design/streaming programs
sudo apt install -y gimp inkscape obs-studio


