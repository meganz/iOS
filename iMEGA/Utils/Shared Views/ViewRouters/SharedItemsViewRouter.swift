import MEGADomain

final class SharedItemsViewRouter: NSObject {
    
    func showShareFoldersContactView(withNodes nodes: [NodeEntity]) {
        let megaNodes = nodes.compactMap {
            MEGASdk.shared.node(forHandle: $0.handle)
        }
        showShareFoldersContactView(withNodes: megaNodes)
    }
    
    func showShareFoldersContactView(withNodes nodes: [MEGANode]) {
        NodeShareRouter(viewController: UIApplication.mnz_visibleViewController())
            .showSharingFolders(for: nodes)
    }
    
    @objc func showPendingOutShareModal(for email: String) {
        CustomModalAlertRouter(.pendingUnverifiedOutShare,
                               presenter: UIApplication.mnz_presentingViewController(),
                               outShareEmail: email).start()
    }
    
}
