#!/usr/bin/env bash

# Get composer
EXPECTED_SIGNATURE="c252c2a2219956f88089ffc242b42c8cb9300a368fd3890d63940e4fc9652345"
php -r "copy('https://getcomposer.org/download/2.4.4/composer.phar', 'composer.phar');"
ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha256', 'composer.phar');")"

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
then
    >&2 echo 'ERROR: Invalid installer signature'
    rm composer-setup.php
    exit 1
fi

# Run composer
php composer-setup.php
rm composer-setup.php

# Remove vendor directory
rm -rf vendor
rm -rf build

# Run composer install
php composer.phar install

# Require and run php-scoper
php composer.phar global require humbug/php-scoper
COMPOSER_BIN_DIR="$(composer global config bin-dir --absolute)"
"$COMPOSER_BIN_DIR"/php-scoper add-prefix

# Dump composer autoload for build folder
php composer.phar dump-autoload --working-dir build --classmap-authoritative

# Remove composer
rm composer.phar

# Remove existing build zip file
rm woocommerce-onpay.zip

# Rsync contents of folder to new directory that we will use for the build
rsync -Rr ./* ./woocommerce-onpay

# Remove directories and files from newly created directory, that we won't need in final build
rm -rf ./woocommerce-onpay/vendor
rm ./woocommerce-onpay/build.sh
rm ./woocommerce-onpay/composer.json
rm ./woocommerce-onpay/composer.lock

# Replace require file with build version
rm ./woocommerce-onpay/require.php
mv ./woocommerce-onpay/require_build.php ./woocommerce-onpay/require.php

# Zip contents of newly created directory
zip -r woocommerce-onpay.zip ./woocommerce-onpay

# Clean up
rm -rf woocommerce-onpay
rm -rf build