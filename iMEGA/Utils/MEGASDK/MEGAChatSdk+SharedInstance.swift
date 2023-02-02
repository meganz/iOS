extension MEGAChatSdk {
    @objc static let shared: MEGAChatSdk = {
        let chatSdk = MEGAChatSdk(MEGASdk.shared)
        MEGASdk.setLogToConsole(false)
        MEGAChatSdk.setLogToConsole(true)
        return chatSdk
    }()
}
