set -x 
mkdir app
cd app
git clone https://github.com/Guy-Davidson/Dynamic.git .
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get install -y awscli
sudo apt-get install -y jq
sudo apt-get install -y npm
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm i -g pm2 
npm i
exit