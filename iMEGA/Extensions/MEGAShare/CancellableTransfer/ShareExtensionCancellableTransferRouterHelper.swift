
@objc final class ShareExtensionCancellableTransferRouterOCWrapper: NSObject {
    @objc func uploadFiles(_ transfers: [CancellableTransfer], toParent parentHandle: MEGAHandle, presenter: UIViewController) {
        ShareExtensionCancellableTransferRouter(presenter: presenter, transfers: transfers, parentNodeHandle: parentHandle).start()
    }
}
