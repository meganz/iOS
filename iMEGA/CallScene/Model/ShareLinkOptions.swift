struct ShareLinkOptions {
    let sender: AnyObject
    let sendLinkToChatAction: () -> Void
    let copyLinkAction: () -> Void
    let shareLinkAction: (UIViewController) -> Void
}
