#!/bin/bash
cd /app/assets
npm install
node_modules/brunch/bin/brunch build --production
cd /app
rm -r _build
mix deps.get
mix phx.digest
mix ecto.create
mix ecto.migrate
mix compile
mix phx.server