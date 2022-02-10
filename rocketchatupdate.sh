#!/bin/bash
echo "Rocket chat server update in..."
secs=$((3))
while [ $secs -gt 0 ]; do
  echo -ne "Start in $secs\033[0K\r"
  sleep 1
  : $((secs--))
done
echo -ne " \033[0K\r"

echo "Start!"
echo
sudo apt update
sudo apt upgrade -y
echo "Stoping service"
sudo systemctl stop rocketchat
echo "Remove install directory"
sudo rm -rf /opt/Rocket.Chat
echo "Cheking for build packages"
sudo apt-get install -y build-essential graphicsmagick
echo "Update the node version"
sudo n install 12.22.1
echo "Download Rocket.Chat latest version"
curl -L https://releases.rocket.chat/latest/download -o /tmp/rocket.chat.tgz
tar -xzf /tmp/rocket.chat.tgz -C /tmp
echo "Install it and set right permissions to Rocket.Chat folder"
cd /tmp/bundle/programs/server && npm install
sudo mv /tmp/bundle /opt/Rocket.Chat
sudo chown -R rocketchat:rocketchat /opt/Rocket.Chat
echo "Start the service"
sudo systemctl start rocketchat
echo "Done"
