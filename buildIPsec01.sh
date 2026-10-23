#!\bin\bash

sudo apt-get update

## Powershell install
# Update package lists and install prerequisites
sudo apt-get install -y wget apt-transport-https software-properties-common
# Download the Microsoft repository keys and configuration
source /etc/os-release
wget -q "https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb"
# Register the Microsoft repository keys
sudo dpkg -i packages-microsoft-prod.deb
# Delete the downloaded package file
rm packages-microsoft-prod.deb
# Update package lists again after adding the new repository
sudo apt-get update
# Install PowerShell
sudo apt-get install -y powershell

## IPsec kernel config
FILE="/etc/sysctl.d/99-ipsec.conf"
if [[ -f "$FILE" ]]; then
    #
else
    sudo touch $FILE
fi

echo "net.ipv4.ip_forward = 1" > $FILE
echo "net.ipv4.conf.all.rp_filter = 2" >> $FILE
echo "net.ipv4.conf.default.rp_filter = 2" >> $FILE
echo "net.ipv4.conf.all.accept_redirects = 0" >> $FILE
echo "net.ipv4.conf.all.send_redirects = 0" >> $FILE

# apply IPsec conf changes
sudo sysctl --system

# clamp TCP MSS so large transfers do not stall
nft add rule inet filter forward oifname "ipsec*" tcp flags syn tcp option maxseg size set rt mtu

## strongSwan Install
# Install apt package
sudo apt-get update  
sudo apt-get install -y charon-systemd strongswan-swanctl libcharon-extra-plugins
# setup system-native daemon, and disable starter wrapper (if present)
sudo systemctl disable --now strongswan-starter 2\>/dev/null || true  
sudo systemctl enable --now strongswan

echo "rebooting in 30s..."
sleep 30
sudo reboot

## strongMan Install on port 1515
#git clone https://github.com/strongswan/strongMan.git
#cd strongMan
#sudo ./setup.py install

# add to strongswan-swanctl.service
# ExecStartPost=/pathTostrongMan/configloader.py
# default login:  http://localhost:1515 Username: John, Password: Lennon@1940
