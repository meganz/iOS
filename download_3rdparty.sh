export PATH=/Applications/MEGAcmd.app/Contents/MacOS:$PATH

if ! type "megacmd" > /dev/null; then
  # install foobar here
	echo "Install MEGACmd before run this script https://mega.nz/cmd"
	exit 1
fi

file="ZZlSzKCQ"
key="pCnK7UKbV3bjZvnRxkHkudcHGQcoarEE8bNlN2WDGfM"
fileUrl="https://mega.nz/#!${file}!${key}"
filePath="./iMEGA/Vendor/SDK/bindings/ios/3rdparty/${file}"

mkdir $filePath
mega-get $fileUrl $filePath
unzip -o ${filePath}/3rdparty.zip -d ./iMEGA/Vendor/SDK/bindings/ios/3rdparty/