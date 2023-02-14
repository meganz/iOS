
extension NodeTableViewCell {
    
    @objc func setTitleAndFolderName(for recentActionBucket: MEGARecentActionBucket,
                                     withNodes nodes: [MEGANode]) {
  
        guard let firstNode = nodes.first else {
            infoLabel.text = ""
            nameLabel.text = ""
            return
        }
        
        let isNodeUndecrypted = firstNode.isUndecrypted(ownerEmail: recentActionBucket.userEmail,
                                                   in: MEGASdkManager.sharedMEGASdk())
        guard !isNodeUndecrypted else {
            infoLabel.text = Strings.Localizable.SharedItems.Tab.Incoming.undecryptedFolderName
            nameLabel.text = Strings.Localizable.SharedItems.Tab.Recents.undecryptedFileName(nodes.count)
            return
        }
        
        let firstNodeName = firstNode.name ?? ""
        nameLabel.text = nodes.count == 1 ? firstNodeName : Strings.Localizable.Home.Recent.multipleFileTitle(firstNodeName, String(nodes.count - 1))

        let parentNode = MEGASdkManager.sharedMEGASdk().node(forHandle: recentActionBucket.parentHandle)
        let parentNodeName = parentNode?.name ?? ""
        infoLabel.text = "\(parentNodeName) ・"
    }
}
