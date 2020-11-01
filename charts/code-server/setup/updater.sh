#!/bin/bash
DOWNLOAD_DIR=/tmp
EXTENSIONS_DIR=/config/extensions

echo "[ Downloading extensions csv ]"
wget https://raw.githubusercontent.com/sqylabs/charts/master/charts/code-server/setup/extensions.csv

while IFS=, read -r publisher extension version;
do
EXTENSION_URL="https://$publisher.gallery.vsassets.io/_apis/public/gallery/publisher/$publisher/extension/$extension/$version/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
echo "[ Downloading $publisher.$extension-$version.vsix ]"
wget $EXTENSION_URL -q -O $DOWNLOAD_DIR/$publisher.$extension-$version.vsix
echo "[ Installing $publisher.$extension-$version ]"
code-server --extensions-dir $EXTENSIONS_DIR --install-extension $DOWNLOAD_DIR/$publisher.$extension-$version.vsix
rm $DOWNLOAD_DIR/$publisher.$extension-$version.vsix
done < <(grep "" extensions.csv)

echo "[ Cleaning up ]"
rm extensions.csv