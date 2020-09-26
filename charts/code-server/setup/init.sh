#!/bin/bash
# Set default directories
HOME_DIR={{ .Values.dirs.home }}
SETUP_DIR={{ .Values.dirs.setup }}
echo "[ Setting setup directory: $SETUP_DIR ]"
DOWNLOAD_DIR={{ .Values.dirs.download }}
echo "[ Setting extension download directory: $DOWNLOAD_DIR ]"
EXTENSIONS_DIR={{ .Values.dirs.extensions }}
echo "[ Setting extension installation directory: $EXTENSIONS_DIR ]"

# Install dependencies
echo "[ Installing dependencies ]"
DEBIAN_FRONTEND=noninteractive \
  apt-get update \
  && apt-get install -qq -y --no-install-recommends zip unzip wget \
  && rm -rf /tmp/* \
  && rm -rf /var/lib/apt/lists/*

# Create setup directory
echo "[ Checking setup directory ]"
if [ ! -d "$SETUP_DIR" ]; then
  echo "[ Creating setup directory ]"
  mkdir -p $SETUP_DIR
else
  echo "[ Setup directory already exists ]"
fi

# Install code-server extensions
echo "[ Checking extension download directory ]"
if [ ! -d "$DOWNLOAD_DIR" ]; then
  echo "[ Creating extension download directory ]"
  mkdir -p $DOWNLOAD_DIR
else
  echo "[ Extension download directory already exists ]"
fi
echo "[ Installing extensions ]"
while IFS=, read -r publisher extension version;
do
  echo "[ Checking $publisher.$extension-$version ]"
  if [ ! -d $(echo $EXTENSIONS_DIR/$publisher.$extension-$version |tr '[:upper:]' '[:lower:]') ]; then
    echo "[ $publisher.$extension-$version is not installed! ]"
    download="https://$publisher.gallery.vsassets.io/_apis/public/gallery/publisher/$publisher/extension/$extension/$version/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
    echo "[ Downloading $publisher.$extension-$version.vsix ]"
    wget $download -q -O $DOWNLOAD_DIR/$publisher.$extension-$version.vsix
    echo "[ Installing $publisher.$extension-$version ]"
    code-server --extensions-dir $EXTENSIONS_DIR --install-extension $DOWNLOAD_DIR/$publisher.$extension-$version.vsix
  else
    echo "[ $publisher.$extension-$version is already installed! ]"
  fi
done < <(grep "" $SETUP_DIR/extensions.csv)

# Install oh-my-bash
echo "[ Installing oh-my-bash ]"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
sed -i 's/OSH_THEME="font"/OSH_THEME="roderik"/g' $HOME_DIR/.bashrc

# Install sdkman
curl -s "https://get.sdkman.io" | bash
source "$HOME_DIR/.sdkman/bin/sdkman-init.sh"

# Set sdkman auto answer
echo "[ Setting sdkman auto answer setting to true ]"
sed -i 's/sdkman_auto_answer=false/sdkman_auto_answer=true/g' $HOME_DIR/.sdkman/etc/config

# Install java
echo "[ Installing java ]"
sdk install java {{ .Values.java.version }}
java -version

# Install native image
echo "[ Installing graalvm native image ]"
gu install native-image
gu list

# Install maven
echo "[ Installing maven ]"
sdk install maven
mvn -version

# Set maven settings.xml
echo "[ Setting maven settings.xml ]"
mkdir -p $HOME_DIR/.m2
cp $SETUP_DIR/settings.xml $HOME_DIR/.m2/settings.xml

# Set settings.json
echo "[ Setting code-server settings.json ]"
mkdir -p $HOME_DIR/data/User
cp $SETUP_DIR/settings.json $HOME_DIR/data/User/settings.json

# Set permissions
echo "[ Setting permissions on home folder ]"
chown -R abc:abc $HOME_DIR