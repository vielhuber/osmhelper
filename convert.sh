#!/usr/bin/env bash

# fetch input
URL=""
LAT_MIN=0
LON_MIN=0
LAT_MAX=0
LON_MAX=0
COMPRESS=0
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
        # --compress
        --compress)
            COMPRESS=1
            ;;
        *)
            echo "unknown option '$key'"
            ;;
    esac
    shift
done

# checks
if [[ -z "$URL" || ! "$URL" =~ ^http(s?)\:\/\/ ]]; then
    echo "--url missing or invalid (example: https://download.geofabrik.de/europe/germany-latest.osm.pbf)"
    exit 1
elif [[ -z "$LAT_MIN" || ! "$LAT_MIN" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo $LAT_MIN
    echo "--lat-min (bottom left breitengrad) missing or invalid (example: 47.27, calculate with https://tools.geofabrik.de/calc)"
    exit 1
elif [[ -z "$LON_MIN" || ! "$LON_MIN" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "--lon-min (bottom left längengrad) missing or invalid (example: 8.97, calculate with https://tools.geofabrik.de/calc)"
    exit 1
elif [[ -z "$LAT_MAX" || ! "$LAT_MAX" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "--lat-max (top right breitengrad) missing or invalid (example: 50.57, calculate with https://tools.geofabrik.de/calc)"
    exit 1
elif [[ -z "$LON_MAX" || ! "$LON_MAX" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "--lon-max (top right längengrad) missing or invalid (example: 13.84, calculate with https://tools.geofabrik.de/calc)"
    exit 1
fi

# download osm.pbf
wget -O ./raw.osm.pbf "$URL"

# set bounding box
osmium extract --strategy=complete_ways --overwrite --bbox="$LON_MIN","$LAT_MIN","$LON_MAX","$LAT_MAX" --set-bounds ./raw.osm.pbf --output ./input.osm.pbf

# prepare tilemaker config + files
git clone https://github.com/systemed/tilemaker.git

# if compression is disabled, modify config (compression reduces filesize by ~60%)
if [ "$COMPRESS" -eq 0 ]; then
    sed -i -E 's|"compress": "(.+)"|"compress": "none"|' ./tilemaker/resources/config-openmaptiles.json
fi

# osm.pbf => pbf
rm -rf ./tiles/
tilemaker --input ./input.osm.pbf --output ./tiles --process ./tilemaker/resources/process-openmaptiles.lua --config ./tilemaker/resources/config-openmaptiles.json

# alternative: osm.pbf => mbtiles => pbf
#tilemaker ./input.osm.pbf --output ./tiles.mbtiles --process ./tilemaker/resources/process-openmaptiles.lua --config ./tilemaker/resources/config-openmaptiles.json
#mb-util ./tiles.mbtiles ./tiles --image_format=pbf

# copy boilerplate
wget -O ./index.html https://raw.githubusercontent.com/vielhuber/osmhelper/refs/heads/main/index.html
wget -O ./fetch.php https://raw.githubusercontent.com/vielhuber/osmhelper/refs/heads/main/fetch.php
sed -i -E 's/LAT_MIN: ([0-9]|\.)+/LAT_MIN: '"$LAT_MIN"'/' ./index.html
sed -i -E 's/LON_MIN: ([0-9]|\.)+/LON_MIN: '"$LON_MIN"'/' ./index.html
sed -i -E 's/LAT_MAX: ([0-9]|\.)+/LAT_MAX: '"$LAT_MAX"'/' ./index.html
sed -i -E 's/LON_MAX: ([0-9]|\.)+/LON_MAX: '"$LON_MAX"'/' ./index.html
if [ "$COMPRESS" -eq 1 ]; then
    wget -O ./.htaccess https://raw.githubusercontent.com/vielhuber/osmhelper/refs/heads/main/.htaccess
else
    echo "" > ./.htaccess
fi

# remove work files
rm -rf ./tilemaker/
rm -f ./input.osm.pbf
rm -f ./raw.osm.pbf
