#! /bin/bash

export PATH=/Applications/MEGAcmd.app/Contents/MacOS:$PATH

if ! type "megacmd" > /dev/null; then
  # install foobar here
	echo "Install MEGACmd before run this script https://mega.nz/cmd"
	exit 1
fi

file="EYECGBDQ"
key="2iFuoLVTqzXA2ARoNJr3tgM0eAlXoT_ce0skKycEF98"
fileUrl="https://mega.nz/#!${file}!${key}"
filePath="./download_3rdparty/${file}"

mkdir -p $filePath
echo "downloading the 3rd party libraries"
mega-get $fileUrl $filePath 
echo "Unzipping the 3rd party libraries"
unzip -o ${filePath}/3rdparty.zip -d ./iMEGA/Vendor/SDK/bindings/ios/3rdparty/
echo "Unzip 3rd party libraries complete"
exit 0