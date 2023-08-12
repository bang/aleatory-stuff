
## installing essential and useful packages
echo "Installing essential modules"
sudo apt install -y vim vim-gtk3 tmux \
git \
build-essential \
vlc \
nmap \
nfs-common \
neofetch \
watchdog 
echo "Done!"

echo "Removing not-want shit!"
# Removing don't-ask-for-install packages from Linux
# * is not working on zsh, I don't know why!
/bin/bash -c "sudo apt purge -y thunderbird* libreoffice*"
echo "Done!"

echo "Installing docker"
## installing docker according to https://docs.docker.com/engine/install/ubuntu/
# removing possible already installed docker package
sudo apt-get remove docker docker-engine docker.io containerd runc
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done


## installing docker dependecies
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    gnupg

# Install keyrings
sudo install -m 0755 -d /etc/apt/keyrings

# adding repos, keys etc
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg


# Set up repository
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$UBUNTU_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

# finally installing docker
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# adding user to docker group
sudo usermod -a -G docker $USER

echo "Done!"

echo "Installing Brave browser"
# Installing brave browser
sudo apt installing -y apt-transport-https curl gnupg
curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -
echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update && sudo apt install -y brave-browser


echo "Installing ohmyzsh"
# Unset ZSH
unset ZSH
# Removing .oh-my-zsh directory
rm -rf ~/.oh-my-zsh
# To remember
ZSH_THEME=refined
# installing ohmyzsh
sudo apt install -y zsh && sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# installing extra fonts for oh my zsh themes
git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
chmod +x install.sh
./install.sh
cd ..
rm -rf fonts

echo "Done!"

# Installing design/streaming programs
echo "Installing design/streaming programs"
sudo apt install -y gimp inkscape obs-studio blender
echo "Done!

