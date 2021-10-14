#!/bin/bash

mkdir -p priv/assets/js
cp assets/*.js \
   deps/phoenix/priv/static/*.js \
   deps/phoenix_live_view/priv/static/*.js \
   priv/assets/js
