import MEGADomain

extension NotificationsTableViewController {
    
    @objc func contentForTakedownReinstatedNode(withHandle handle: HandleEntity, nodeFont: UIFont) -> NSAttributedString? {
        guard let node = MEGASdkManager.sharedMEGASdk().node(forHandle: handle) else { return nil }
        let nodeName = node.name ?? ""
        switch node.type {
        case .file:
            return contentMessageAttributedString(withNodeName: nodeName,
                                                  nodeFont: nodeFont,
                                                  message: Strings.Localizable.Notifications.Message.TakenDownReinstated.file(nodeName))
        case .folder:
            return contentMessageAttributedString(withNodeName: nodeName,
                                                  nodeFont: nodeFont,
                                                  message: Strings.Localizable.Notifications.Message.TakenDownReinstated.folder(nodeName))
        default: return nil
        }
    }
    
    @objc func contentForTakedownPubliclySharedNode(withHandle handle: HandleEntity, nodeFont: UIFont) -> NSAttributedString? {
        guard let node = MEGASdkManager.sharedMEGASdk().node(forHandle: handle) else { return nil }
        let nodeName = node.name ?? ""
        switch node.type {
        case .file:
            return contentMessageAttributedString(withNodeName: nodeName,
                                                  nodeFont: nodeFont,
                                                  message: Strings.Localizable.Notifications.Message.TakenDownPubliclyShared.file(nodeName))
        case .folder:
            return contentMessageAttributedString(withNodeName: nodeName,
                                                  nodeFont: nodeFont,
                                                  message: Strings.Localizable.Notifications.Message.TakenDownPubliclyShared.folder(nodeName))
        default: return nil
        }
    }
    
    private func contentMessageAttributedString(withNodeName nodeName: String,
                                                nodeFont: UIFont,
                                                message: String) -> NSAttributedString? {
        let contentAttributedText = NSMutableAttributedString(string: message)
        if let nodeNameRange = message.range(of: nodeName) {
            contentAttributedText.addAttributes([.font: nodeFont], range: NSRange(nodeNameRange, in: message))
        }
        return contentAttributedText
    }
}
