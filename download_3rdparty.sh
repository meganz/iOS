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
filePath="./../download_3rdparty/${file}"

mkdir -p $filePath
echo "downloading the 3rd party libraries"
mega-get $fileUrl $filePath 


# Sometimes the submodules might take time to run, so the folder might not exists.
# We have 5 attemps to check if the folder exists with 20 seconds apart.
attempt=0
until [ ! $attempt -lt 5 ] || [ -d "./iMEGA/Vendor/SDK/bindings/ios/3rdparty" ]
do
   attempt=`expr $attempt + 1`
   echo "Attempt number: $attempt. The folder does not exists. Waiting for 20 seconds and trying it again."
   sleep 20 
done

if [ ! -d "./iMEGA/Vendor/SDK/bindings/ios/3rdparty" ] 
then
   echo "Could not unzip the 3rd party libraries"
   exit 1 
else
   echo "Unzipping the 3rd party libraries"
   unzip -o ${filePath}/3rdparty.zip -d ./iMEGA/Vendor/SDK/bindings/ios/3rdparty/
   echo "Unzip 3rd party libraries complete"
   exit 0
fi