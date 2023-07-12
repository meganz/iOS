#! /bin/bash

sdkThirdPartyPath="./Modules/DataSource/MEGASDK/Sources/MEGASDK/bindings/ios/3rdparty"
chatThirdPartyPath="./Modules/DataSource/MEGAChatSDK/Sources/MEGAChatSDK/bindings/Objective-C/3rdparty"

echo "Create include and lib folders in 3rdparty for chat"

mkdir $chatThirdPartyPath/include
mkdir $chatThirdPartyPath/lib

echo "Copy headers needed by MEGAChat"

cp -R $sdkThirdPartyPath/webrtc $chatThirdPartyPath/

cp -R ./Modules/DataSource/MEGASDK/Sources/MEGASDK/bindings/ios/mega $chatThirdPartyPath/include

cp ./Modules/DataSource/MEGASDK/Sources/MEGASDK/bindings/ios/private/DelegateMEGARequestListener.h $chatThirdPartyPath/include
cp ./Modules/DataSource/MEGASDK/Sources/MEGASDK/bindings/ios/private/DelegateMEGATransferListener.h $chatThirdPartyPath/include
cp ./Modules/DataSource/MEGASDK/Sources/MEGASDK/bindings/ios/private/MEGAHandleList+init.h $chatThirdPartyPath/include
cp ./Modules/DataSource/MEGASDK/Sources/MEGASDK/bindings/ios/private/MEGANode+init.h $chatThirdPartyPath/include
cp ./Modules/DataSource/MEGASDK/Sources/MEGASDK/bindings/ios/private/MEGANodeList+init.h $chatThirdPartyPath/include
cp ./Modules/DataSource/MEGASDK/Sources/MEGASDK/bindings/ios/private/MEGASdk+init.h $chatThirdPartyPath/include
cp ./Modules/DataSource/MEGASDK/Sources/MEGASDK/bindings/ios/private/MEGAStringList+init.h $chatThirdPartyPath/include

echo "Move xcframeworks needed by MEGAChat"

mv $sdkThirdPartyPath/lib/libnative_api.xcframework $chatThirdPartyPath/lib
mv $sdkThirdPartyPath/lib/libnative_video.xcframework $chatThirdPartyPath/lib
mv $sdkThirdPartyPath/lib/libvideocapture_objc.xcframework $chatThirdPartyPath/lib
mv $sdkThirdPartyPath/lib/libvideoframebuffer_objc.xcframework $chatThirdPartyPath/lib
mv $sdkThirdPartyPath/lib/libwebsockets.xcframework $chatThirdPartyPath/lib
