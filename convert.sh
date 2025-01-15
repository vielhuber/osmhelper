#!/usr/bin/env bash

# fetch input
URL=""
LAT_MIN=0
LON_MIN=0
LAT_MAX=0
LON_MAX=0
while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
        # --url value
        --url)
        shift
        URL="$1"
        ;;
        # --lat-min value
        --lat-min)
        shift
        LAT_MIN="$1"
        ;;
        # --lon-min value
        --lon-min)
        shift
        LON_MIN="$1"
        ;;
        # --lat-max value
        --lat-max)
        shift
        LAT_MAX="$1"
        ;;
        # --lon-max value
        --lon-max)
        shift
        LON_MAX="$1"
        ;;
        *)
        echo "Unknown option '$key'"
        ;;
    esac
    shift
done

# checks
if [[ -z "$URL" || ! "$URL" =~ ^http\:\/\/ ]]; then
  echo "--url missing or invalid (example: https://download.geofabrik.de/europe/germany-latest.osm.pbf)"
else
if [[ -n "$LAT_MIN" || ! "$LAT_MIN" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "--lat-min (bottom left breitengrad) missing or invalid (example: 47.27, calculate with https://tools.geofabrik.de/calc)"
else
if [[ -n "$LON_MIN" || ! "$LON_MIN" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "--lon-min (bottom left längengrad) missing or invalid (example: 8.97, calculate with https://tools.geofabrik.de/calc)"
else
if [[ -n "$LAT_MAX" || ! "$LAT_MAX" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "--lat-max (top right breitengrad) missing or invalid (example: 50.57, calculate with https://tools.geofabrik.de/calc)"
else
if [[ -n "$LON_MAX" || ! "$LON_MAX" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "--lon-max (top right längengrad) missing or invalid (example: 13.84, calculate with https://tools.geofabrik.de/calc)"
else

# download osm.pbf
wget -nc -O ./raw.osm.pbf "$URL"

# set bounding box
osmium extract --strategy=complete_ways --overwrite --bbox="$LON_MIN","$LAT_MIN","$LON_MAX","$LAT_MAX" --set-bounds ./raw.osm.pbf --output ./input.osm.pbf

# prepare tilemaker config + files
git clone https://github.com/systemed/tilemaker.git
sed -i -E 's|"compress": "(.+)"|"compress": "none"|' ./tilemaker/resources/config-openmaptiles.json ## modify config

# osm.pbf => pbf
rm -rf ./tiles/
tilemaker --input ./input.osm.pbf --output ./tiles --process ./tilemaker/resources/process-openmaptiles.lua --config ./tilemaker/resources/config-openmaptiles.json

# alternative: osm.pbf => mbtiles => pbf
#tilemaker ./input.osm.pbf --output ./tiles.mbtiles --process ./tilemaker/resources/process-openmaptiles.lua --config ./tilemaker/resources/config-openmaptiles.json
#mb-util ./tiles.mbtiles ./tiles --image_format=pbf

# copy boilerplate
wget -O ./index.html https://raw.githubusercontent.com/vielhuber/osmhelper/refs/heads/master/index.html
wget -O ./fetch.php https://raw.githubusercontent.com/vielhuber/osmhelper/refs/heads/master/fetch.php
sed -i -E 's/LAT_MIN: ([0-9]|\.)+/LAT_MIN: '"$LAT_MIN"'/' ./index.html
sed -i -E 's/LON_MIN: ([0-9]|\.)+/LON_MIN: '"$LON_MIN"'/' ./index.html
sed -i -E 's/LAT_MAX: ([0-9]|\.)+/LAT_MAX: '"$LAT_MAX"'/' ./index.html
sed -i -E 's/LON_MAX: ([0-9]|\.)+/LON_MAX: '"$LON_MAX"'/' ./index.html

# remove work files
rm -rf ./tilemaker/
rm -f ./input.osm.pbf
rm -f ./raw.osm.pbf
