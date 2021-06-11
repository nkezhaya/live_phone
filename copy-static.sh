#!/bin/bash

mkdir -p priv/assets/js
cp assets/*.js \
   deps/phoenix/priv/static/*.js \
   deps/phoenix_live_view/priv/static/*.js \
   priv/assets/js

echo $(pwd)

echo $(ls)
echo $(ls priv)
echo $(ls priv/assets)
echo $(ls priv/assets/js)
echo $(ls _build/test/lib/live_phone/priv/assets/js)
