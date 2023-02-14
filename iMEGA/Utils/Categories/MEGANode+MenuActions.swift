
extension MEGANode {
    
    //MARK: - Remove Link
    @objc func mnz_removeLink() {
        let nodeArray = [self]
        nodeArray.mnz_removeLinks()
    }
    
    //MARK: - Import
    func openBrowserToImport(in viewController: UIViewController) {
        let storyboard = UIStoryboard(name: "Cloud", bundle: nil)
        guard let browserVC = storyboard.instantiateViewController(withIdentifier: "BrowserViewControllerID") as? BrowserViewController
        else { return }
        browserVC.selectedNodesArray = [self]
        browserVC.browserAction = .import
        let browserNC = MEGANavigationController(rootViewController: browserVC)
        browserNC.setToolbarHidden(false, animated: false)
        viewController.present(browserNC, animated: true, completion: nil)
    }
    
}

extension Array where Element == MEGANode {
    
    //MARK: - Remove Link
    func mnz_removeLinks() {
        guard !isEmpty else { return }
        let linkNodesCount = count
        let isMultipleLink = linkNodesCount > 1
        
        forEach { node in
            MEGASdkManager.sharedMEGASdk()
                .disableExport(node, delegate: MEGAExportRequestDelegate.init(completion: { request in
                    let message = Strings.Localizable.General.MenuAction.RemoveLink.Message.success(linkNodesCount)
                    SVProgressHUD.showSuccess(withStatus: message)
                }, multipleLinks: isMultipleLink))
        }
    }
}
