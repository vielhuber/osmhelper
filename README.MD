# 🗺️ osmhelper 🗺️

osmhelper helps you hosting openstreetmap statically. it creates vector tiles from `.osm.pbf` files with user defined bounding boxes and creates suitable boilerplate files you just need to upload and are ready to go.

# installation

```sh
## osmium
mkdir osmium
cd osmium
wget https://github.com/osmcode/osmium-tool/archive/refs/tags/v1.16.0.tar.gz
tar -xzf v1.16.0.tar.gz
cd osmium-tool-1.16.0
apt-get install libosmium2-dev libprotozero-dev nlohmann-json3-dev libboost-program-options-dev libbz2-dev zlib1g-dev liblz4-dev libexpat1-dev cmake pandoc
mkdir build
cd build
cmake ..
make
make install
cd ..
cd ..
rm -rf ./osmium/
exec env -i HOME=$HOME bash -l
osmium --version

## mbutil
git clone https://github.com/mapbox/mbutil.git
cd mbutil
python setup.py install
cd ..
rm -rf ./mbutil/
exec env -i HOME=$HOME bash -l
mb-util --version

## tilemaker
apt install build-essential libboost-dev libboost-filesystem-dev libboost-program-options-dev libboost-system-dev lua5.1 liblua5.1-0-dev libshp-dev libsqlite3-dev rapidjson-dev
git clone https://github.com/systemed/tilemaker.git
cd tilemaker
make
make install
cd ..
rm -rf ./tilemaker
exec env -i HOME=$HOME bash -l
tilemaker --help

## conversion script
mkdir openstreetmap
cd openstreetmap
wget -O ./convert.sh https://raw.githubusercontent.com/vielhuber/osmhelper/refs/heads/master/convert.sh
chmod +x convert.sh
```

# usage

```sh
./convert.sh \
    --url https://download.geofabrik.de/europe/germany-latest.osm.pbf \
    --lat-min 47.27 \
    --lon-min 8.97 \
    --lat-max 50.57 \
    --lon-max 13.84 \
    --compress
```
