#! /bin/bash

export PATH=/Applications/MEGAcmd.app/Contents/MacOS:$PATH

if ! type "megacmd" > /dev/null; then
  # install foobar here
	echo "Install MEGACmd before run this script https://mega.nz/cmd"
	exit 1
fi

file="9JkihTSQ"
key="os6Y7slroj3lUeYgzec5VdAP6PjzTzu1oa-bq8yzcAw"
fileUrl="https://mega.nz/#!${file}!${key}"
filePath="./download_3rdparty/${file}"

echo "create directory started $filePath"
mkdir -p $filePath
echo "create directory completed"
echo "Downloading 3rd party libraries from $fileUrl to file path $filePath"
mega-get $fileUrl $filePath 
echo "Downloading 3rd party libraries complete"
echo "Unzip 3rd party libraries start"
unzip -o ${filePath}/3rdparty.zip -d ./iMEGA/Vendor/SDK/bindings/ios/3rdparty/
echo "Unzip 3rd party libraries complete"
exit 0