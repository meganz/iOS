import UIKit

public struct ShareLinkOptions {
    public let sendLinkToChatAction: () -> Void
    public let copyLinkAction: () -> Void
    public let shareLinkAction: (UIViewController) -> Void
    
    public init(
        sendLinkToChatAction: @escaping () -> Void,
        copyLinkAction: @escaping () -> Void,
        shareLinkAction: @escaping (UIViewController) -> Void
    ) {
        self.sendLinkToChatAction = sendLinkToChatAction
        self.copyLinkAction = copyLinkAction
        self.shareLinkAction = shareLinkAction
    }
}
