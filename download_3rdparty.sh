export PATH=/Applications/MEGAcmd.app/Contents/MacOS:$PATH

if ! type "megacmd" > /dev/null; then
  # install foobar here
	echo "Install MEGACmd before run this script https://mega.nz/cmd"
	exit 1
fi

file="1Zl3DKRY"
key="eHs48TtPaQ9TfXKf6HFppyyrA3LkmFVSYwuxTEN4qy0"
fileUrl="https://mega.nz/#!${file}!${key}"
filePath="./download_3rdparty/${file}"

mkdir -p $filePath
mega-get $fileUrl $filePath
unzip -o ${filePath}/3rdparty.zip -d ./iMEGA/Vendor/SDK/bindings/ios/3rdparty/
mv ./iMEGA/Vendor/SDK/bindings/ios/3rdparty/3rdparty/include ./iMEGA/Vendor/SDK/bindings/ios/3rdparty/
mv ./iMEGA/Vendor/SDK/bindings/ios/3rdparty/3rdparty/webrtc ./iMEGA/Vendor/SDK/bindings/ios/3rdparty/
mv ./iMEGA/Vendor/SDK/bindings/ios/3rdparty/3rdparty/lib ./iMEGA/Vendor/SDK/bindings/ios/3rdparty/