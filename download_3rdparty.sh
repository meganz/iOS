export PATH=/Applications/MEGAcmd.app/Contents/MacOS:$PATH

if ! type "megacmd" > /dev/null; then
  # install foobar here
	echo "Install MEGACmd before run this script https://mega.nz/cmd"
	exit 1
fi


mega-get https://mega.nz/#!ZZlSzKCQ!pCnK7UKbV3bjZvnRxkHkudcHGQcoarEE8bNlN2WDGfM ./iMEGA/Vendor/SDK/bindings/ios/3rdparty/
unzip -o ./iMEGA/Vendor/SDK/bindings/ios/3rdparty/3rdparty.zip -d ./iMEGA/Vendor/SDK/bindings/ios/3rdparty/