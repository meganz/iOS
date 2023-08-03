import ChatRepo

extension MEGAChatSdk {
    @objc static let shared: MEGAChatSdk = {
#if MNZ_NOTIFICATION_EXTENSION
        let chatSdk = MEGAChatSdk(MEGASdk.sharedNSE)
        MEGASdk.setLogToConsole(false)
        MEGAChatSdk.setLogToConsole(true)
#else
        let chatSdk = MEGAChatSdk.sharedChatSdk
#endif
        return chatSdk
    }()
}
