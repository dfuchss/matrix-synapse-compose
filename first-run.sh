#!/bin/bash

##############################################
### CHECKS ###################################
##############################################

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

## Fix Permissions
chown -R root.root templates

if [ -d "./synapse" ]
  then echo "Script has already been executed .. please delete created files to rerun"
  exit
fi

##############################################
### VERSIONS #################################
##############################################

WAIT_RELEASE=2.7.3

##############################################
### VARS #####################################
##############################################

echo "Welcome! You have to run this script once to create the necessary config files."
echo "Please check that you've installed docker, docker-compose, openssl, and wget !"
echo ""

echo "Please enter your homeserver (e.g. matrix.tld.com): "
read homeserver

echo "Please enter your desired virtual subnet for the matrix-services (e.g. 192.168.100.1/24): "
read subnet



##### SYNAPSE & POSTGRES #####

echo "Generating conf to $(pwd)/synapse/homeserver.yaml ... you have to edit some stuff that you want to modify"
mkdir synapse
docker run -it --rm -v $(pwd)/synapse:/data -e SYNAPSE_SERVER_NAME=$homeserver -e SYNAPSE_REPORT_STATS=yes matrixdotorg/synapse generate

echo "Downloading Waiting Tool ..."
wget -q https://github.com/ufoscout/docker-compose-wait/releases/download/$WAIT_RELEASE/wait > /dev/null
chmod a+x wait

echo "Creating Matrix Docker Network ..."
docker network create matrix --subnet "$subnet"

echo "Fixing DB URL ..."

POSTGRES_PASS=$(openssl rand -hex 48)

START_LINE=$(awk '/^database:$/{ print NR; exit }' ./synapse/homeserver.yaml)
END_LINE=$(awk '/^\s*database: \/data\/homeserver\.db$/{ print NR; exit }' ./synapse/homeserver.yaml)

cp ./synapse/homeserver.yaml ./synapse/homeserver.yaml.orig
head -n $((START_LINE - 1)) ./synapse/homeserver.yaml.orig > ./synapse/homeserver.yaml
sed "s/<<PASSWORD>>/"$POSTGRES_PASS"/g" templates/synapse-db.template >> ./synapse/homeserver.yaml
tail -n +$((END_LINE + 1)) ./synapse/homeserver.yaml.orig >> ./synapse/homeserver.yaml
rm ./synapse/homeserver.yaml.orig

sed "s/<<PASSWORD>>/$POSTGRES_PASS/g" templates/docker-compose.yml.template > docker-compose.yml



### APACHE CONF #####
echo "Creating Apache2 Sample Configuration (no SSL) at $(pwd)/matrix-$homeserver.conf"
sed "s/<<SERVER_NAME>>/$homeserver/g" templates/matrix-apache.conf.template > matrix-$homeserver.conf

### MAUTRIX TELEGRAM #####
echo ""
echo "Configuring Mautrix Telegram"
mkdir mautrix-telegram
docker run --rm -v $(pwd)/mautrix-telegram:/data dock.mau.dev/tulir/mautrix-telegram

echo "Enter your Telegram API ID:"
read tg_api
echo "Enter your Telegram API Hash:"
read tg_hash

START_LINE=$(awk '/permissions:$/{ print NR; exit }' ./mautrix-telegram/config.yaml)
END_LINE=$(awk '/admin:example.com/{ print NR; exit }' ./mautrix-telegram/config.yaml)

cp ./mautrix-telegram/config.yaml ./mautrix-telegram/config.yaml.orig
head -n $((START_LINE - 1)) ./mautrix-telegram/config.yaml.orig > ./mautrix-telegram/config.yaml
sed "s/<<HOMESERVER>>/"$homeserver"/g" templates/mautrix-permissions.template >> ./mautrix-telegram/config.yaml
tail -n +$((END_LINE + 1)) ./mautrix-telegram/config.yaml.orig >> ./mautrix-telegram/config.yaml
rm ./mautrix-telegram/config.yaml.orig

sed -i "s/address: https:\/\/example\.com/address: http:\/\/synapse:8008/g" mautrix-telegram/config.yaml
sed -i "s/domain: example\.com/domain: $homeserver/g" mautrix-telegram/config.yaml
sed -i "s/address: http:\/\/localhost:29317/address: http:\/\/mautrix-telegram:29317/g" mautrix-telegram/config.yaml
sed -i "s/\s*api_id: [0-9]*$/    api_id: $tg_api/g" mautrix-telegram/config.yaml
sed -i "s/\s*api_hash: [0-9a-z]*$/    api_hash: $tg_hash/g" mautrix-telegram/config.yaml

docker run --rm -v $(pwd)/mautrix-telegram:/data dock.mau.dev/tulir/mautrix-telegram

echo "Register Mautrix Telegram .."
cp mautrix-telegram/registration.yaml synapse/mautrix-telegram-registration.yaml

START_LINE=$(awk '/app_service_config_files:$/{ print NR; exit }' ./synapse/homeserver.yaml)
END_LINE=$(awk '/- app_service_2.yaml/{ print NR; exit }' ./synapse/homeserver.yaml)

cp ./synapse/homeserver.yaml ./synapse/homeserver.yaml.orig
head -n $((START_LINE - 1)) ./synapse/homeserver.yaml.orig > ./synapse/homeserver.yaml
cat templates/mautrix-appservice.template >> ./synapse/homeserver.yaml
tail -n +$((END_LINE + 1)) ./synapse/homeserver.yaml.orig >> ./synapse/homeserver.yaml
rm synapse/homeserver.yaml.orig

echo ""
echo "######################################################################"
echo "# Please Modify your homeserver.yaml file on your will ..            #"
echo "# You have to state your admin users in mautrix-telegram/config.yaml #"
echo "# Also take a look at the apache configuration in this directory.    #"
echo "######################################################################"

