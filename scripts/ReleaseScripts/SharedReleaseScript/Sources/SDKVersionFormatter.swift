import Foundation

public struct SDKVersionFormatter {
    private let sdkVersion: SubmoduleReferenceType
    private let chatSDKVersion: SubmoduleReferenceType

    public init(sdkVersion: SubmoduleReferenceType, chatSDKVersion: SubmoduleReferenceType) {
        self.sdkVersion = sdkVersion
        self.chatSDKVersion = chatSDKVersion
    }

    public func formatted(prefix: String = "-", plainText: Bool = true) -> String {
        """
        \(prefix) \(sdkVersion.description(for: .sdk, plainText: plainText))
        \(prefix) \(chatSDKVersion.description(for: .chatSDK, plainText: plainText))
        """
    }
}
