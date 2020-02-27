
if ! type "megacmd" > /dev/null; then
  # install foobar here
	echo "Install MEGACmd before run this script https://mega.nz/cmd"
	exit 1
fi
export PATH=/Applications/MEGAcmd.app/Contents/MacOS:$PATH


mega-get https://mega.nz/#!BUtgzAQL!rf6stzMWq-RJ9u9-l8jeYZ0kSd07fwSDSG3P3Uj9Mx0 ./iMEGA/Vendor/SDK/bindings/ios/3rdparty/
unzip -o ./iMEGA/Vendor/SDK/bindings/ios/3rdparty/3rdparty.zip -d ./iMEGA/Vendor/SDK/bindings/ios/3rdparty/