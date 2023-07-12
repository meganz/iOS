#! /bin/bash

export PATH=/Applications/MEGAcmd.app/Contents/MacOS:$PATH

if ! type "megacmd" > /dev/null; then
  # install foobar here
	echo "Install MEGACmd before run this script https://mega.nz/cmd"
	exit 1
fi

echo "${PWD}"
file="kbZTXIqY"
key="o8rQAOveVwuVHyvNKLbQ4skSNzHgj5IlHmXVGmKajQw"
fileLinkUrl="https://mega.nz/#!${file}!${key}"
downloadFilePath="./../download_3rdparty/${file}"
unzipPath="./Modules/DataSource/MEGASDK/Sources/MEGASDK/bindings/ios/3rdparty"

mkdir -p $downloadFilePath
echo "downloading the 3rd party libraries"
mega-get $fileLinkUrl $downloadFilePath 


# Sometimes the submodules might take time to run, so the folder might not exists.
# We have 5 attemps to check if the folder exists with 20 seconds apart.
attempt=0
until [ ! $attempt -lt 5 ] || [ -d $unzipPath ]
do
   attempt=`expr $attempt + 1`
   echo "Attempt number: $attempt. The folder does not exists. Waiting for 20 seconds and trying it again."
   sleep 20 
done

if [ ! -d $unzipPath ] 
then
   echo "Could not unzip the 3rd party libraries as the folder doesn't exist"
   exit 1 
else
   echo "Unzipping the 3rd party libraries"
   unzip -o ${downloadFilePath}/3rdparty.zip -d $unzipPath
   echo "Unzip 3rd party libraries complete"
fi

sh setup_chatSDK.sh
   
exit 0
