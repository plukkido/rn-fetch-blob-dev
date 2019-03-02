#!/bin/bash

set -e

TEST_APP_NAME='RNFetchBlobTest'
TEST_APP_PATH="$(pwd)/${TEST_APP_NAME}"
TARGET='android'
CWD=$(pwd)

if [ "$#" -eq 1 ]; then
  if [ "$1" == 'android' ]; then
    TARGET="$1"
    echo 'start android test'
  elif [ "$1" == 'ios' ]; then
    TARGET="$1"
    echo 'start ios test'
  else
    exit "unrecongized target platform $1, please specify a target platform `ios` or `android`."
  fi
elif [ "$#" -gt 2 ] && [ "$1" == 'path' ]; then
  TEST_APP_PATH="$2"
  TARGET="$3"
  echo "use exist test app path=$2 target=$3"
else
  exit "unrecongized arguments."
fi


# Create new rn project
if [ "$#" -eq 1 ]; then
  echo 'creating test app RNFetchBlobTest ..'
  react-native init "${TEST_APP_NAME}"
fi
# copy js files to test app folder, along with the config.json file
cp -R test/ "${TEST_APP_PATH}/"
cp config.json "${TEST_APP_PATH}/" || true
node -e "var fs=require('fs'); var pkg = JSON.parse(fs.readFileSync('./RNFetchBlobTest/package.json')); pkg.rnpm = {assets : ['assets']}; fs.writeFileSync('./RNFetchBlobTest/package.json', JSON.stringify(pkg, null, 4));"

# install module
cd "${TEST_APP_PATH}"
# npm install --save "${CWD}/src"
npm install --save react-native-fetch-blob
# libs that requires web API polyfills
npm install --save firebase
npm install --save crypto-js
npm install -save react-native-image-picker
react-native link

# copy android assets
cd ${CWD}
cp -R ./test/assets/ ./RNFetchBlobTest/android/app/src/main/assets/

# patch settings.gradle
patch -p0 <<EOF
--- RNFetchBlobTest/android/settings.gradle     2019-03-02 18:23:40.000000000 +0100
+++ RNFetchBlobTest/android/settings.gradle     2019-03-02 18:24:09.000000000 +0100
@@ -2,6 +2,6 @@
 include ':react-native-image-picker'
 project(':react-native-image-picker').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-image-picker/android')
 include ':react-native-fetch-blob'
-project(':react-native-fetch-blob').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-fetch-blob/android')
+project(':react-native-fetch-blob').projectDir = new File(rootProject.projectDir, '../../src/android')

 include ':app'
EOF

# start RN
cd "${TEST_APP_PATH}"
if [ "$#" == 4 ]; then
  sed -i.bak "s/${TEST_APP_NAME}/$4/" ./index.test.js
fi
react-native "run-${TARGET}"

# install dev packages
cd ${CWD}
npm install
# start test server
cd "${CWD}/test-server"
# kill existing server
kill "$(lsof | grep :8123 | awk '{ printf $2 }')" || true
node server
