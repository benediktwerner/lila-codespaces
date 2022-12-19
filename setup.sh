#!/bin/sh

sudo service nginx restart
cd /workspace
git clone https://github.com/lichess-org/lila.git
git clone https://github.com/lichess-org/lila-ws.git
git clone https://github.com/lichess-org/lila-db-seed.git
git clone https://github.com/lichess-org/lila-engine.git
git clone https://github.com/lichess-org/fishnet.git --recursive
git clone https://github.com/lichess-org/lila-fishnet.git
git clone https://github.com/lichess-org/pgn-viewer.git
## Create config for lila
cp /workspace/lila/conf/application.conf.default /workspace/lila/conf/application.conf
tee -a /workspace/lila/conf/application.conf <<EOF
net.site.name = "lila-gitpod"
net.domain = "$(gp url 8080 | cut -c9-)"
net.socket.domains = [ "$(gp url 8080 | cut -c9-)" ]
net.base_url = "$(gp url 8080)"
net.asset.base_url = "$(gp url 8080)"
externalEngine.endpoint = "$(gp url 9666)"
EOF
## Create config for lila-ws (websockets)
tee /workspace/lila-ws-gitpod-application.conf <<EOF
include "application"
csrf.origin = "$(gp url 8080)"
EOF
## Create config for fishnet clients
tee /workspace/fishnet/fishnet.ini <<EOF
[fishnet]
cores=auto
systembacklog=long
userbacklog=short
EOF
## Setup initial database and seed test data (users, games, puzzles, etc)
mkdir -p /workspace/mongodb-data
sudo mongod --fork --dbpath /workspace/mongodb-data --logpath /var/log/mongod.log
mongo lichess /workspace/lila/bin/mongodb/indexes.js
python3.9 /workspace/lila-db-seed/spamdb/spamdb.py --drop all
redis-server --daemonize yes
gp sync-done setup
## Switch editor to lila workspace
open --reuse-window /workspace/lila
