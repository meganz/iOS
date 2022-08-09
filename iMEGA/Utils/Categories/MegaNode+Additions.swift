
extension MEGANode {
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
    
    /// Create an NSAttributedString with the name of the node and append isTakedown image
    /// - Returns: The name of the node appending isTakedown image at the end
    @objc func attributedTakenDownName() -> NSAttributedString {
        let name = NSMutableAttributedString(string: self.name?.appending(" ") ?? "")

        let takedownImageAttachment = NSTextAttachment()
        takedownImageAttachment.image = UIImage(named: "isTakedown")
        let takedownImageString = NSAttributedString(attachment: takedownImageAttachment)
        
        name.append(takedownImageString)
        
        return name
    }
}
