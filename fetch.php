<?php
final class Fetch
{
    private $force = false;

    private $custom_style = true;

    public function init()
    {
        $file = 'style.json';
        if (isset($_GET['file'])) {
            if (!in_array($_GET['file'], ['metadata.json'])) {
                die();
            }
            $file = $_GET['file'];
        }

        header('Content-Type: application/json; charset=utf-8');

        $content = '';

        $baseurl = rtrim(
            'http' .
                (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off' ? 's' : '') .
                '://' .
                $_SERVER['HTTP_HOST'] .
                dirname($_SERVER['PHP_SELF']),
            '/'
        );

        if ($file === 'style.json') {
            if (
                $this->force === true ||
                !file_exists('./tiles/finished.log') ||
                file_get_contents('./tiles/finished.log') === ($this->custom_style === true ? 'default' : 'custom')
            ) {
                // rm -rf ./tiles/fonts/ ./tiles/style.json
                @unlink('./tiles/style.json');
                $this->removeDir('./tiles/fonts/');

                // download
                file_put_contents(
                    './tiles/tilemaker-master.zip',
                    file_get_contents('https://github.com/systemed/tilemaker/archive/refs/heads/master.zip')
                );

                // unzip
                $zip = new \ZipArchive();
                $res = $zip->open('./tiles/tilemaker-master.zip');
                $zip->extractTo('./tiles/');
                $zip->close();

                // cp -R ./tiles/tilemaker-master/server/static/fonts ./tiles/
                $cpSource = './tiles/tilemaker-master/server/static/fonts';
                $cpDest = './tiles/fonts';
                mkdir($cpDest);
                foreach (
                    $iterator = new \RecursiveIteratorIterator(
                        new \RecursiveDirectoryIterator($cpSource, \RecursiveDirectoryIterator::SKIP_DOTS),
                        \RecursiveIteratorIterator::SELF_FIRST
                    )
                    as $item
                ) {
                    if ($item->isDir()) {
                        mkdir($cpDest . DIRECTORY_SEPARATOR . $iterator->getSubPathname());
                    } else {
                        copy($item, $cpDest . DIRECTORY_SEPARATOR . $iterator->getSubPathname());
                    }
                }

                // default style
                if (1 === 1) {
                    // cp -R ./tilemaker/server/static/style.json ./tiles/
                    copy('./tiles/tilemaker-master/server/static/style.json', './tiles/style.json');

                    /*
                    wget -O ./tiles/sprite.json https://openmaptiles.github.io/osm-bright-gl-style/sprite.json
                    wget -O ./tiles/sprite.png https://openmaptiles.github.io/osm-bright-gl-style/sprite.png
                    */
                    file_put_contents(
                        './tiles/sprite.json',
                        file_get_contents('https://openmaptiles.github.io/osm-bright-gl-style/sprite.json')
                    );
                    file_put_contents(
                        './tiles/sprite.png',
                        file_get_contents('https://openmaptiles.github.io/osm-bright-gl-style/sprite.png')
                    );
                    file_put_contents(
                        './tiles/sprite@2x.json',
                        file_get_contents('https://openmaptiles.github.io/osm-bright-gl-style/sprite@2x.json')
                    );
                    file_put_contents(
                        './tiles/sprite@2x.png',
                        file_get_contents('https://openmaptiles.github.io/osm-bright-gl-style/sprite@2x.png')
                    );
                }
                // custom style from https://github.com/teamapps-org/maplibre-gl-styles/
                if ($this->custom_style === true) {
                    file_put_contents(
                        './tiles/style.json',
                        file_get_contents(
                            'https://raw.githubusercontent.com/teamapps-org/maplibre-gl-styles/refs/heads/main/positron/style-cdn.json'
                        )
                    );

                    file_put_contents(
                        './tiles/sprite.json',
                        file_get_contents(
                            'https://raw.githubusercontent.com/teamapps-org/maplibre-gl-styles/refs/heads/main/positron/sprite.json'
                        )
                    );
                    file_put_contents(
                        './tiles/sprite.png',
                        file_get_contents(
                            'https://raw.githubusercontent.com/teamapps-org/maplibre-gl-styles/refs/heads/main/positron/sprite.png'
                        )
                    );
                    file_put_contents(
                        './tiles/sprite@2x.json',
                        file_get_contents(
                            'https://raw.githubusercontent.com/teamapps-org/maplibre-gl-styles/refs/heads/main/positron/sprite@2x.json'
                        )
                    );
                    file_put_contents(
                        './tiles/sprite@2x.png',
                        file_get_contents(
                            'https://raw.githubusercontent.com/teamapps-org/maplibre-gl-styles/refs/heads/main/positron/sprite@2x.png'
                        )
                    );

                    // custom fonts (https://maplibre.org/font-maker/)
                    $this->removeDir('./tiles/fonts/');
                    file_put_contents(
                        './tiles/fonts.zip',
                        file_get_contents('https://github.com/openmaptiles/fonts/releases/download/v2.0/v2.0.zip')
                    );
                    $zip = new \ZipArchive();
                    $res = $zip->open('./tiles/fonts.zip');
                    $zip->extractTo('./tiles/fonts/');
                    $zip->close();
                }

                // rm -rf ./tiles/tilemaker-master/
                // rm -f ./tiles/tilemaker-master.zip
                if (1 === 1) {
                    $this->removeDir('./tiles/tilemaker-master/');
                    @unlink('./tiles/tilemaker-master.zip');
                    @unlink('./tiles/fonts.zip');
                }

                file_put_contents('./tiles/finished.log', $this->custom_style ? 'custom' : 'default');
            }

            $content = file_get_contents('./tiles/' . $file);
            $content = preg_replace(
                '/"url": "(.+)\.json(.*)"/',
                '"url": "' . $baseurl . '/fetch.php?file=metadata.json"',
                $content
            );
            $content = preg_replace(
                '/"glyphs": "(.+)\/fonts\/\{fontstack\}\/\{range\}\.pbf(.*)"/',
                '"glyphs": "' . $baseurl . '/tiles/fonts/{fontstack}/{range}.pbf"',
                $content
            );
            // concatenated fonts are not supported, since we don't have a tileserver
            $content = preg_replace(
                '/"text-font": \[(?:\n|.)*?"(.+?)"(?:\n|.)*?\],/',
                '"text-font": ["$1"],',
                $content
            );

            $content = preg_replace(
                '/"sprite": "(.+)\/sprite"/',
                '"sprite": "' . $baseurl . '/tiles/sprite"',
                $content
            );
        }

        if ($file === 'metadata.json') {
            $content = file_get_contents('./tiles/' . $file);
            $content = preg_replace(
                '/"tiles":\["(.+)\/{z}\/{x}\/{y}.pbf"\]/',
                '"tiles":["' . $baseurl . '/tiles/{z}/{x}/{y}.pbf"]',
                $content
            );
        }

        echo $content;
        die();
    }

    public function removeDir($dir)
    {
        if (!is_dir($dir)) {
            return;
        }
        $it = new RecursiveDirectoryIterator($dir, RecursiveDirectoryIterator::SKIP_DOTS);
        $files = new RecursiveIteratorIterator($it, RecursiveIteratorIterator::CHILD_FIRST);
        foreach ($files as $file) {
            if ($file->isDir()) {
                rmdir($file->getPathname());
            } else {
                unlink($file->getPathname());
            }
        }
        rmdir($dir);
    }
}

$f = new Fetch();
$f->init();
