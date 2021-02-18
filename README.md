# Matrix Synapse Compose
This repository contains some code for the automatic setup of [synapse](https://github.com/matrix-org/synapse) and [mautrix-telegram](https://github.com/tulir/mautrix-telegram).

## Getting started
Just download this repository and execute the `first-run.sh`. After that you can modify the configs on your behalf.
The created configuration assumes a reverse proxy to be set up.
A sample configuration for [apache2](https://httpd.apache.org/) will be created automatically.

*You may need to define the admin user of mautrix telegram. By default the generated config contains an `@admin:<<homeserver>>` as admin user. Nevertheless, this user will not be created automatically.*

## Troubleshooting
If the network for the docker compose configuration cannot be created (e.g. because of a running OpenVPN connection cf. [Stackoverflow](https://stackoverflow.com/questions/45692255/how-make-openvpn-work-with-docker)), you may use `docker network create matrix --subnet "192.168.100.1/24"` to create a docker network and set it in the generated docker-compose file.

