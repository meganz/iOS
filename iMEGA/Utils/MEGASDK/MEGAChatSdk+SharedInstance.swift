extension MEGAChatSdk {
    @objc static let shared: MEGAChatSdk = {
#if MNZ_NOTIFICATION_EXTENSION
        let chatSdk = MEGAChatSdk(MEGASdk.sharedNSE)
#else
        let chatSdk = MEGAChatSdk(MEGASdk.shared)
#endif
        MEGASdk.setLogToConsole(false)
        MEGAChatSdk.setLogToConsole(true)
        return chatSdk
    }()
}
