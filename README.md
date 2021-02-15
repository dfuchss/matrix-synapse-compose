# Matrix Synapse Compose
This repository contains some code for the automatic setup of [synapse](https://github.com/matrix-org/synapse) and [mautrix-telegram](https://github.com/tulir/mautrix-telegram).

## Getting started
Just download this repository and execute the `first-run.sh`. After that you can modify the configs on your behalf.
The created configuration assumes a reverse proxy to be set up.
A sample configuration for [apache2](https://httpd.apache.org/) will be created automatically.

*You may need to define the admin user of mautrix telegram. By default the generated config contains an `@admin:<<homeserver>>` as admin user. Nevertheless, this user will not be created automatically.*
