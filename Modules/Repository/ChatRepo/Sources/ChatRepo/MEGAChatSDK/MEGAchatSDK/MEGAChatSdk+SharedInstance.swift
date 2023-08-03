import MEGAChatSdk
import MEGASDKRepo

public extension MEGAChatSdk {
    static let sharedChatSdk: MEGAChatSdk = {
        let chatSdk = MEGAChatSdk(MEGASdk.sharedSdk)
        MEGASdk.setLogToConsole(false)
        MEGAChatSdk.setLogToConsole(true)
        return chatSdk
    }()
}

extension MEGAChatSdk: @unchecked Sendable { }
