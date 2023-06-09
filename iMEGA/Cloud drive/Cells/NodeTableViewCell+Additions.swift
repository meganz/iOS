
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
        let nodesCount = nodes.count
        nameLabel.text = nodesCount == 1 ? firstNodeName : Strings.Localizable.Recents.Section.MultipleFile.title(nodesCount - 1).replacingOccurrences(of: "[A]", with: firstNodeName)

        let parentNode = MEGASdkManager.sharedMEGASdk().node(forHandle: recentActionBucket.parentHandle)
        let parentNodeName = parentNode?.name ?? ""
        infoLabel.text = "\(parentNodeName) ・"
    }
}
